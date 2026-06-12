# frozen_string_literal: true

namespace :search do
  desc "Compare FTS-only vs Hybrid search quality (MRR, NDCG@10, Recall@10)"
  task benchmark: :environment do
    unless Rails.env.test?
      puts "⚠️  벤치마크는 테스트 환경에서만 실행할 수 있습니다."
      puts "   실행 방법: RAILS_ENV=test bin/rails search:benchmark"
      next
    end
    seed_benchmark_data!
    stub_embeddings_for_benchmark!

    eval_data = load_eval_queries
    if eval_data.empty?
      puts "평가 쿼리가 없습니다. test/data/search_eval_queries.yml을 확인하세요."
      next
    end

    queries       = eval_data.map { |e| e[:query] }
    relevant_sets = eval_data.map { |e| e[:relevant_ids] }

    puts "=== 검색 품질 벤치마크 ==="
    puts "쿼리 수: #{queries.size}"
    puts

    fts_ranked    = queries.map { |q| Article.kept.confirmed.full_text_search_for(q).limit(100).pluck(:id).uniq }
    hybrid_ranked = queries.map { |q| Articles::HybridSearch.call(query: q, limit: 100) }

    require "search_benchmark"

    first_rel  = relevant_sets.map(&:first)
    fts_mrr    = SearchBenchmark.mrr(fts_ranked, first_rel)
    hybrid_mrr = SearchBenchmark.mrr(hybrid_ranked, first_rel)
    fts_ndcg    = SearchBenchmark.ndcg_at(fts_ranked, relevant_sets, k: 10)
    hybrid_ndcg = SearchBenchmark.ndcg_at(hybrid_ranked, relevant_sets, k: 10)
    fts_recall    = SearchBenchmark.recall_at(fts_ranked, relevant_sets, k: 10)
    hybrid_recall = SearchBenchmark.recall_at(hybrid_ranked, relevant_sets, k: 10)

    puts "| 메트릭     | FTS-only | Hybrid   | 개선율   |"
    puts "|------------|----------|----------|----------|"
    puts "| MRR        | #{fmt(fts_mrr)}    | #{fmt(hybrid_mrr)}    | #{delta(fts_mrr, hybrid_mrr)} |"
    puts "| NDCG@10    | #{fmt(fts_ndcg)}    | #{fmt(hybrid_ndcg)}    | #{delta(fts_ndcg, hybrid_ndcg)} |"
    puts "| Recall@10  | #{fmt(fts_recall)}    | #{fmt(hybrid_recall)}    | #{delta(fts_recall, hybrid_recall)} |"
    puts

    puts "--- 쿼리별 상세 ---"
    queries.each_with_index do |q, i|
      ftop = fts_ranked[i].first(5)
      htop = hybrid_ranked[i].first(5)
      rel  = relevant_sets[i]
      puts "  \"#{q}\""
      puts "    relevant: #{rel}"
      puts "    FTS top-5:    #{ftop} #{hits(ftop & rel)}"
      puts "    Hybrid top-5: #{htop} #{hits(htop & rel)}"
      puts
    end
  end

  # -------------------------------------------------------------------
  # helpers
  # -------------------------------------------------------------------

  # 테스트 환경에서 RubyLLM.embed를 모의 응답으로 대체한다.
  # 실제 API 키가 없어도 벤치마크가 벡터 검색 경로를 시뮬레이션할 수 있게 한다.
  def stub_embeddings_for_benchmark!
    return if @_stubbed
    @_stubbed = true

    Rails.cache.clear

    # 벤치마크 환경에서는 결정적 mock embedding을 사용한다.
    # 1536차원에서 코사인 유사도가 의미 있으려면 대부분의 차원이 0에 가까워야 한다.
    # neighbor gem SQL 생성을 위해 완전 0 대신 아주 작은 noise를 사용한다.
    RubyLLM.define_singleton_method(:embed) do |text, model: nil, dimensions: nil|
      t = text.to_s.downcase.gsub(/[^a-z0-9가-힣\s]/, " ")

      # 신호 차원: 쿼리 키워드와 seed 데이터 간 연관성
      signal = Array.new(1536, 0.0)
      signal[0] = 0.95 if t.match?(/ruby|성능|속도|speed|optimization|yjit|compile|컴파일|execution/)
      signal[1] = 0.95 if t.match?(/nlp|한국어|자연어|인공지능|transformer|토크나이저|korean|ai|language/)
      signal[2] = 0.95 if t.match?(/rails|async|query|비동기|load|database/)
      signal[0] = 0.6 if signal[0] == 0.0 && signal[1] == 0.0 && signal[2] == 0.0

      # 각 차원에 미세 noise 추가 (SQL safety + cosine stability)
      vec = signal.map.with_index { |s, i| s + rand(-0.01..0.01) }
      OpenStruct.new(vectors: vec)
    end
  end

  def mock_embedding(text)
    vec = Array.new(1536, 0.0)
    t = text.to_s.downcase.gsub(/[^a-z0-9가-힣\s]/, " ")

    # benchmark seed 데이터의 mock embedding과 정렬된 키워드→차원 매핑
    vec[0] = 0.85 if t.match?(/ruby|성능|속도|speed|optimization|yjit|compile|컴파일|execution/)
    vec[1] = 0.85 if t.match?(/nlp|한국어|자연어|인공지능|transformer|토크나이저|korean|ai|language/)
    vec[2] = 0.85 if t.match?(/rails|async|query|비동기|load|database/)

    # 어떤 키워드와도 매칭되지 않으면 Ruby 임베딩 근처로 (기본 연관)
    if vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0
      vec[0] = 0.5
    end

    OpenStruct.new(vectors: vec)
  end

  def seed_benchmark_data!
    return if Article.where(title_ko: "[BENCH] Ruby 3.4 성능 최적화").exists?

    site = Site.first || Site.create!(name: "benchmark", url: "https://example.com")
    user = User.first || (u = User.new(email: "bench@example.com", password: "benchmark123", username: "benchmark", confirmed_at: Time.current); u.save!(validate: false); u)

    data = [
      { tko: "[BENCH] Ruby 3.4 성능 최적화",  ten: "Ruby 3.4 Performance Optimization",
        body: "Ruby 3.4 brings exciting new features including improved performance and better syntax. YJIT 최적화로 성능이 크게 향상되었습니다.",
        sum: "Ruby 3.4 performance improvements with YJIT optimization",
        pg: "Ruby 3.4 performance optimization YJIT compiler speed improvement 새로운 기능 속도 향상",
        emb: (Array.new(1536, 0.0)).tap { |v| v[0] = 1.0 } },
      { tko: "[BENCH] 한국어 NLP 기술 동향",   ten: "Korean NLP Technology Trends",
        body: "한국어 자연어 처리 기술의 최신 동향. Transformer 기반 모델과 한국어 특화 토크나이저의 발전.",
        sum: "Korean NLP technology trends with transformer models",
        pg: "한국어 자연어 처리 NLP 인공지능 기술 동향 Transformer 모델 토크나이저",
        emb: (Array.new(1536, 0.0)).tap { |v| v[1] = 1.0 } },
      { tko: "[BENCH] Rails 8 비동기 쿼리 가이드", ten: "Rails 8 Async Query Guide",
        body: "Rails 8 introduces async query loading for better performance. Learn how to use load_async to speed up database queries.",
        sum: "Rails 8 async query loading guide",
        pg: "Rails 8 async query loading performance load_async database",
        emb: (Array.new(1536, 0.0)).tap { |v| v[2] = 1.0 } },
      # --- noise articles (무관 기사, 임베딩은 다른 차원으로) ---
      { tko: "[BENCH] 파이썬 3.13 릴리스 노트", ten: "Python 3.13 Release Notes",
        body: "Python 3.13 introduces a new interactive interpreter and improved error messages.",
        sum: "Python 3.13 release highlights",
        pg: "Python 3.13 release interactive interpreter error messages GIL",
        emb: (Array.new(1536, 0.0)).tap { |v| v[100] = 1.0 } },
      { tko: "[BENCH] 리눅스 커널 6.10 변경사항", ten: "Linux Kernel 6.10 Changes",
        body: "Linux 6.10 brings improved Rust support, new hardware drivers.",
        sum: "Linux kernel 6.10 changes",
        pg: "Linux kernel 6.10 Rust support hardware drivers filesystem",
        emb: (Array.new(1536, 0.0)).tap { |v| v[101] = 1.0 } },
      { tko: "[BENCH] React 19 서버 컴포넌트", ten: "React 19 Server Components",
        body: "React 19 introduces server components, actions, and improved hydration.",
        sum: "React 19 server components guide",
        pg: "React 19 server components actions hydration full-stack",
        emb: (Array.new(1536, 0.0)).tap { |v| v[102] = 1.0 } },
      { tko: "[BENCH] PostgreSQL 17 병렬 쿼리", ten: "PostgreSQL 17 Parallel Query",
        body: "PostgreSQL 17 improves parallel query execution and logical replication.",
        sum: "PostgreSQL 17 parallel query improvements",
        pg: "PostgreSQL 17 parallel query execution logical replication backup",
        emb: (Array.new(1536, 0.0)).tap { |v| v[103] = 1.0 } },
      { tko: "[BENCH] Swift 6 동시성 모델", ten: "Swift 6 Concurrency Model",
        body: "Swift 6 introduces full data-race safety with strict concurrency checking.",
        sum: "Swift 6 concurrency model overview",
        pg: "Swift 6 concurrency data-race safety actors sendable",
        emb: (Array.new(1536, 0.0)).tap { |v| v[104] = 1.0 } }
    ]

    data.each do |d|
      a = Article.new(site:, user:, title_ko: d[:tko], title: d[:ten],
                      body: d[:body], summary_body: d[:sum], published_at: 1.day.ago, is_related: true,
                      origin_url: "benchmark://#{d[:tko].hash.abs}", slug: d[:tko].parameterize)
      a.save!(validate: false)

      if d[:emb]
        a.update_column(:embedding, d[:emb])
      end

      existing = ActiveRecord::Base.connection.execute(
        "SELECT 1 FROM pg_search_documents WHERE searchable_type = 'Article' AND searchable_id = #{a.id}"
      )
      if existing.ntuples > 0
        ActiveRecord::Base.connection.execute(
          "UPDATE pg_search_documents SET content = #{Article.connection.quote(d[:pg])}, updated_at = NOW() " \
          "WHERE searchable_type = 'Article' AND searchable_id = #{a.id}"
        )
      else
        ActiveRecord::Base.connection.execute(
          "INSERT INTO pg_search_documents (searchable_type, searchable_id, content, created_at, updated_at) " \
          "VALUES ('Article', #{a.id}, #{Article.connection.quote(d[:pg])}, NOW(), NOW())"
        )
      end
    end

    puts "벤치마크 데이터 #{data.size}개 생성 완료"
  end

  def load_eval_queries
    path = Rails.root.join("test/data/search_eval_queries.yml")
    return [] unless path.exist?

    data = YAML.safe_load_file(path, permitted_classes: [ Symbol ]) || {}
    data.values.map do |entry|
      titles = Array(entry["relevant_titles"])
      ids = Article.where(title_ko: titles).pluck(:id)
      { query: entry["query"], relevant_ids: ids }
    end
  rescue StandardError => e
    puts "평가 쿼리 로드 실패: #{e.message}"
    []
  end

  def fmt(v)  = format("%.4f", v)

  def delta(before, after)
    return "  N/A  " if before.zero? && after.zero?
    return "  NEW  " if before.zero?
    format("%+#.1f%%", ((after - before) / before * 100))
  end

  def hits(ids)
    ids.empty? ? "" : " ✓ hit: #{ids}"
  end
end
