# Articles 하이브리드 검색 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 벡터 검색과 전문 검색을 RRF로 병합하고 임계값 필터·MMR 재순위를 더한 하이브리드 검색 엔진을 도입해 메인 검색과 에이전트 도구에 연결한다.

**Architecture:** 융합 프리미티브(코사인·RRF·MMR)를 DB 없는 순수 함수로 분리하고, `Articles::HybridSearch` 오케스트레이터가 임베딩(캐시)→벡터NN+FTS→RRF→임계값→선택적 MMR을 조합한다. 결과 ID를 `in_order_of`로 관계 복원해 기존 호출부에 끼운다.

**Tech Stack:** Rails 8.1, Minitest + fixtures, `ruby_llm`(gemini-embedding-001, 1536d), `neighbor`(pgvector HNSW euclidean), Solid Cache, `pg_search`.

설계 문서: `docs/superpowers/specs/2026-06-11-hybrid-search-design.md`

---

## TDD 규율: Canon TDD (Kent Beck)

이 플랜은 **Canon TDD**로 실행한다. 각 Task의 테스트 코드 블록은 한꺼번에 작성하는 파일이 아니라
**테스트 리스트**다. 실행 루프:

1. Task의 테스트 리스트를 확인한다(이미 플랜에 나열됨).
2. 리스트에서 **정확히 하나**의 테스트만 파일에 추가한다 → 실행해 **Red** 확인.
3. 그 테스트 + **기존 모든 테스트**가 통과하도록 최소 구현을 추가/수정한다 → **Green** 확인.
4. (선택) 리팩터링 — 테스트 유지한 채 구조 개선.
5. 리스트의 다음 테스트로 2로 돌아간다. 구현 중 새 케이스를 발견하면 리스트에 추가한다.

즉 "테스트 파일 전체 작성 → 구현 전체 작성"(배치)은 금지. 한 컴포넌트의 구현은 그 컴포넌트의
테스트를 하나씩 Green으로 만들며 점진적으로 완성한다. 커밋은 Task 단위(리스트가 비고 전체 Green일 때).

아래 각 Task의 "테스트 리스트"는 추가 순서대로 나열돼 있다. 위에서부터 하나씩 적용하라.

---

## File Structure

생성:
- `app/functions/search/vector_math.rb` — `cosine_similarity(a, b)` 순수 함수 (MMR·임계값 공용)
- `app/functions/search/reciprocal_rank_fusion.rb` — 순위 리스트 융합
- `app/functions/search/maximal_marginal_relevance.rb` — 다양성 재순위
- `app/functions/articles/hybrid_search.rb` — 오케스트레이터
- `test/functions/search/vector_math_test.rb`
- `test/functions/search/reciprocal_rank_fusion_test.rb`
- `test/functions/search/maximal_marginal_relevance_test.rb`
- `test/functions/articles/hybrid_search_test.rb`
- `test/functions/articles/query_test.rb`

수정:
- `app/functions/articles/query.rb` — 검색 분기를 HybridSearch로 교체, 정렬 책임 이동
- `app/controllers/articles_controller.rb:27` — 검색 시 `.order(published_at:)` 미적용
- `app/tools/search_related_articles.rb` — `query` 경로를 HybridSearch로 교체

각 Task 후 `eval "$(rbenv init -)"`로 Ruby 환경을 활성화해 명령을 실행한다(프로젝트 Ruby 버전 매니저). 아래 명령은 활성화가 끝난 셸을 가정한다.

---

### Task 1: 코사인 유사도 순수 함수

**Files:**
- Create: `app/functions/search/vector_math.rb`
- Test: `test/functions/search/vector_math_test.rb`

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/search/vector_math_test.rb
# frozen_string_literal: true

require "test_helper"

class Search::VectorMathTest < ActiveSupport::TestCase
  test "identical vectors have similarity 1.0" do
    assert_in_delta 1.0, Search::VectorMath.cosine_similarity([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]), 1e-9
  end

  test "orthogonal vectors have similarity 0.0" do
    assert_in_delta 0.0, Search::VectorMath.cosine_similarity([1.0, 0.0], [0.0, 1.0]), 1e-9
  end

  test "opposite vectors have similarity -1.0" do
    assert_in_delta(-1.0, Search::VectorMath.cosine_similarity([1.0, 0.0], [-1.0, 0.0]), 1e-9)
  end

  test "zero vector yields 0.0 without raising" do
    assert_equal 0.0, Search::VectorMath.cosine_similarity([0.0, 0.0], [1.0, 2.0])
  end

  test "nil or empty input yields 0.0" do
    assert_equal 0.0, Search::VectorMath.cosine_similarity(nil, [1.0])
    assert_equal 0.0, Search::VectorMath.cosine_similarity([], [])
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/functions/search/vector_math_test.rb`
Expected: FAIL — `uninitialized constant Search::VectorMath`

- [ ] **Step 3: Write minimal implementation**

```ruby
# app/functions/search/vector_math.rb
# frozen_string_literal: true
# rbs_inline: enabled

module Search
  module VectorMath
    module_function

    #: (Array[Float]? a, Array[Float]? b) -> Float
    def cosine_similarity(a, b)
      return 0.0 if a.blank? || b.blank? || a.size != b.size

      dot = 0.0
      norm_a = 0.0
      norm_b = 0.0
      a.each_index do |i|
        av = a[i].to_f
        bv = b[i].to_f
        dot += av * bv
        norm_a += av * av
        norm_b += bv * bv
      end
      return 0.0 if norm_a.zero? || norm_b.zero?

      dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/functions/search/vector_math_test.rb`
Expected: PASS (5 runs, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add app/functions/search/vector_math.rb test/functions/search/vector_math_test.rb
git commit -m "Add cosine similarity vector math helper"
```

---

### Task 2: Reciprocal Rank Fusion 순수 함수

**Files:**
- Create: `app/functions/search/reciprocal_rank_fusion.rb`
- Test: `test/functions/search/reciprocal_rank_fusion_test.rb`

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/search/reciprocal_rank_fusion_test.rb
# frozen_string_literal: true

require "test_helper"

class Search::ReciprocalRankFusionTest < ActiveSupport::TestCase
  test "single list preserves order" do
    assert_equal [10, 20, 30], Search::ReciprocalRankFusion.call([[10, 20, 30]])
  end

  test "id appearing high in both lists ranks first" do
    list_a = [2, 1, 3]
    list_b = [2, 3, 1]
    # id 2 is rank-0 in both lists -> highest RRF score -> first
    assert_equal 2, Search::ReciprocalRankFusion.call([list_a, list_b]).first
  end

  test "deduplicates ids across lists" do
    result = Search::ReciprocalRankFusion.call([[1, 2], [2, 1]])
    assert_equal [1, 2].sort, result.sort
    assert_equal 2, result.size
  end

  test "ignores empty lists" do
    assert_equal [5, 6], Search::ReciprocalRankFusion.call([[5, 6], []])
  end

  test "returns empty for no input" do
    assert_equal [], Search::ReciprocalRankFusion.call([])
    assert_equal [], Search::ReciprocalRankFusion.call([[], []])
  end

  test "k parameter changes weighting toward larger k flattening" do
    # With very large k, rank differences shrink; order falls back to first-seen stability
    result = Search::ReciprocalRankFusion.call([[1, 2], [2, 3]], k: 1_000_000)
    assert_includes result, 1
    assert_includes result, 2
    assert_includes result, 3
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/functions/search/reciprocal_rank_fusion_test.rb`
Expected: FAIL — `uninitialized constant Search::ReciprocalRankFusion`

- [ ] **Step 3: Write minimal implementation**

```ruby
# app/functions/search/reciprocal_rank_fusion.rb
# frozen_string_literal: true
# rbs_inline: enabled

module Search
  module ReciprocalRankFusion
    DEFAULT_K = 60

    module_function

    # 여러 순위 ID 리스트를 RRF 점수로 병합한다. 점수 정규화 없이 순위만 사용한다.
    # score(id) = Σ_over_lists 1.0 / (k + rank), rank는 0부터.
    #: (Array[Array[Integer]] ranked_lists, ?k: Integer) -> Array[Integer]
    def call(ranked_lists, k: DEFAULT_K)
      scores = Hash.new(0.0)
      first_seen = {}
      order = 0

      ranked_lists.each do |list|
        next if list.blank?

        list.each_with_index do |id, rank|
          scores[id] += 1.0 / (k + rank)
          unless first_seen.key?(id)
            first_seen[id] = order
            order += 1
          end
        end
      end

      scores.keys.sort_by { |id| [-scores[id], first_seen[id]] }
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/functions/search/reciprocal_rank_fusion_test.rb`
Expected: PASS (6 runs, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add app/functions/search/reciprocal_rank_fusion.rb test/functions/search/reciprocal_rank_fusion_test.rb
git commit -m "Add reciprocal rank fusion function"
```

---

### Task 3: Maximal Marginal Relevance 순수 함수

**Files:**
- Create: `app/functions/search/maximal_marginal_relevance.rb`
- Test: `test/functions/search/maximal_marginal_relevance_test.rb`

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/search/maximal_marginal_relevance_test.rb
# frozen_string_literal: true

require "test_helper"

class Search::MaximalMarginalRelevanceTest < ActiveSupport::TestCase
  # query ~ [1,0]. Candidates: a,b nearly identical (high relevance, low diversity),
  # c orthogonal (lower relevance, high diversity).
  def candidates
    [
      { id: :a, vector: [1.0, 0.0] },
      { id: :b, vector: [0.99, 0.01] },
      { id: :c, vector: [0.0, 1.0] }
    ]
  end

  test "first pick is the most relevant to the query" do
    result = Search::MaximalMarginalRelevance.call(
      query_vector: [1.0, 0.0], candidates: candidates, lambda: 0.7, limit: 3
    )
    assert_equal :a, result.first
  end

  test "diversity beats a near-duplicate for the second slot" do
    # With lambda 0.5, after picking :a, :c (diverse) should beat :b (near-dup of :a)
    result = Search::MaximalMarginalRelevance.call(
      query_vector: [1.0, 0.0], candidates: candidates, lambda: 0.5, limit: 2
    )
    assert_equal [:a, :c], result
  end

  test "returns all candidates when limit exceeds candidate count" do
    result = Search::MaximalMarginalRelevance.call(
      query_vector: [1.0, 0.0], candidates: candidates, lambda: 0.7, limit: 10
    )
    assert_equal 3, result.size
    assert_equal [:a, :b, :c].sort, result.sort
  end

  test "empty candidates returns empty" do
    assert_equal [], Search::MaximalMarginalRelevance.call(
      query_vector: [1.0, 0.0], candidates: [], lambda: 0.7, limit: 5
    )
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/functions/search/maximal_marginal_relevance_test.rb`
Expected: FAIL — `uninitialized constant Search::MaximalMarginalRelevance`

- [ ] **Step 3: Write minimal implementation**

```ruby
# app/functions/search/maximal_marginal_relevance.rb
# frozen_string_literal: true
# rbs_inline: enabled

module Search
  module MaximalMarginalRelevance
    module_function

    # 관련도(쿼리 유사도)와 다양성(선택된 후보와의 비유사도)의 균형으로 재순위한다.
    # 매 단계 argmax: λ·cos(query, d) − (1−λ)·max_{s∈selected} cos(d, s)
    #: (query_vector: Array[Float], candidates: Array[Hash[Symbol, untyped]], lambda: Float, limit: Integer) -> Array[untyped]
    def call(query_vector:, candidates:, lambda:, limit:)
      remaining = candidates.dup
      selected = []

      query_sim = remaining.to_h do |c|
        [c[:id], Search::VectorMath.cosine_similarity(query_vector, c[:vector])]
      end

      until remaining.empty? || selected.size >= limit
        best = remaining.max_by do |c|
          diversity_penalty =
            if selected.empty?
              0.0
            else
              selected.map { |s| Search::VectorMath.cosine_similarity(c[:vector], s[:vector]) }.max
            end
          (lambda * query_sim[c[:id]]) - ((1 - lambda) * diversity_penalty)
        end

        selected << best
        remaining.delete(best)
      end

      selected.map { |c| c[:id] }
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/functions/search/maximal_marginal_relevance_test.rb`
Expected: PASS (4 runs, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add app/functions/search/maximal_marginal_relevance.rb test/functions/search/maximal_marginal_relevance_test.rb
git commit -m "Add maximal marginal relevance reranking function"
```

---

### Task 4: Articles::HybridSearch 오케스트레이터

**Files:**
- Create: `app/functions/articles/hybrid_search.rb`
- Test: `test/functions/articles/hybrid_search_test.rb`

이 Task는 임베딩 API를 stub한다. `RubyLLM.embed`는 `.vectors` 응답 객체를 반환하므로
테스트용 Struct로 대체한다. 픽스처 `ruby_article`은 `is_related: true`, `slug: "ruby-3-4-features"`이고
본문/요약에 "Ruby" 텍스트가 있어 FTS로 매칭된다. confirmed(slug+title_ko 존재) 조건도 만족한다.

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/articles/hybrid_search_test.rb
# frozen_string_literal: true

require "test_helper"

class Articles::HybridSearchTest < ActiveSupport::TestCase
  EmbedResult = Struct.new(:vectors)

  def stub_embed(vector)
    RubyLLM.stub(:embed, EmbedResult.new(vector)) { yield }
  end

  test "blank query returns empty array" do
    assert_equal [], Articles::HybridSearch.call(query: "")
    assert_equal [], Articles::HybridSearch.call(query: "   ")
  end

  test "falls back to FTS-only ids when embedding fails" do
    RubyLLM.stub(:embed, ->(*) { raise StandardError, "api down" }) do
      ids = Articles::HybridSearch.call(query: "Ruby")
      assert_includes ids, articles(:ruby_article).id
    end
  end

  test "returns FTS matches when embedding succeeds but no article embeddings exist" do
    Rails.cache.clear
    stub_embed(Array.new(1536, 0.0).tap { |v| v[0] = 1.0 }) do
      ids = Articles::HybridSearch.call(query: "Ruby")
      assert_includes ids, articles(:ruby_article).id
    end
  end

  test "vector-matched article surfaces via embedding similarity" do
    Rails.cache.clear
    target = articles(:ruby_article)
    qvec = Array.new(1536, 0.0)
    qvec[0] = 1.0
    target.update_column(:embedding, qvec)

    stub_embed(qvec) do
      ids = Articles::HybridSearch.call(query: "zzznontextmatch")
      assert_includes ids, target.id
    end
  end

  test "caches the query embedding across calls" do
    Rails.cache.clear
    calls = 0
    embed = lambda do |*|
      calls += 1
      EmbedResult.new(Array.new(1536, 0.0).tap { |v| v[0] = 1.0 })
    end
    RubyLLM.stub(:embed, embed) do
      Articles::HybridSearch.call(query: "CacheTerm")
      Articles::HybridSearch.call(query: "CacheTerm")
    end
    assert_equal 1, calls
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/functions/articles/hybrid_search_test.rb`
Expected: FAIL — `uninitialized constant Articles::HybridSearch`

- [ ] **Step 3: Write minimal implementation**

```ruby
# app/functions/articles/hybrid_search.rb
# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module HybridSearch
    extend FunctionLogger

    CANDIDATE_POOL = 100
    RRF_K = 60
    COSINE_THRESHOLD = 0.6
    MMR_LAMBDA = 0.7
    EMBED_CACHE_TTL = 12.hours
    EMBED_MODEL = "gemini-embedding-001"
    EMBED_DIMENSIONS = 1536

    class << self
      #: (query: String, ?limit: Integer, ?mmr: bool) -> Array[Integer]
      def call(query:, limit: 20, mmr: false)
        term = query.to_s.strip
        return [] if term.blank?

        qvec = query_embedding(term)
        vector_hits = qvec ? vector_search(qvec) : []
        fts_ids = fts_search(term)

        fused = Search::ReciprocalRankFusion.call([vector_hits.map(&:first), fts_ids], k: RRF_K)
        return fused.first(limit) if fused.empty? || qvec.nil?

        vectors = candidate_vectors(fused)
        kept = threshold_filter(fused, vectors, qvec, fts_ids)
        ranked = mmr ? rerank(kept, vectors, qvec, limit) : kept
        ranked.first(limit)
      end

      private

      # 정규화 쿼리를 캐시 키로 임베딩을 조회/저장한다. 실패 시 nil 폴백.
      #: (String term) -> Array[Float]?
      def query_embedding(term)
        Rails.cache.fetch(cache_key(term), expires_in: EMBED_CACHE_TTL) do
          RubyLLM.embed(term, model: EMBED_MODEL, dimensions: EMBED_DIMENSIONS).vectors.to_a
        end
      rescue StandardError => e
        logger.warn "HybridSearch embedding failed for #{term.inspect}: #{e.message}"
        nil
      end

      #: (String term) -> String
      def cache_key(term)
        "hybrid_search/embedding/#{EMBED_MODEL}/#{Digest::SHA256.hexdigest(term.downcase)}"
      end

      # [[id, distance], ...] euclidean 근접 후보.
      #: (Array[Float] qvec) -> Array[[Integer, Float]]
      def vector_search(qvec)
        Article.kept.confirmed
               .nearest_neighbors(:embedding, qvec, distance: "euclidean")
               .limit(CANDIDATE_POOL)
               .pluck(:id, :neighbor_distance)
      end

      #: (String term) -> Array[Integer]
      def fts_search(term)
        Article.kept.confirmed.full_text_search_for(term).limit(CANDIDATE_POOL).pluck(:id)
      end

      # 후보 ID들의 임베딩을 한 번에 로드한다. nil 임베딩은 제외.
      #: (Array[Integer] ids) -> Hash[Integer, Array[Float]]
      def candidate_vectors(ids)
        Article.where(id: ids).where.not(embedding: nil)
               .pluck(:id, :embedding)
               .to_h { |id, vec| [id, Array(vec).map(&:to_f)] }
      end

      # 벡터 출신 후보 중 코사인 유사도 < 임계값 제거. FTS 매칭 후보는 통과.
      #: (Array[Integer] fused, Hash[Integer, Array[Float]] vectors, Array[Float] qvec, Array[Integer] fts_ids) -> Array[Integer]
      def threshold_filter(fused, vectors, qvec, fts_ids)
        fts_set = fts_ids.to_set
        fused.select do |id|
          next true if fts_set.include?(id)

          vec = vectors[id]
          vec && Search::VectorMath.cosine_similarity(qvec, vec) >= COSINE_THRESHOLD
        end
      end

      #: (Array[Integer] ids, Hash[Integer, Array[Float]] vectors, Array[Float] qvec, Integer limit) -> Array[Integer]
      def rerank(ids, vectors, qvec, limit)
        candidates = ids.filter_map do |id|
          vec = vectors[id]
          { id: id, vector: vec } if vec
        end
        no_vec = ids - candidates.map { |c| c[:id] }
        reranked = Search::MaximalMarginalRelevance.call(
          query_vector: qvec, candidates: candidates, lambda: MMR_LAMBDA, limit: limit
        )
        (reranked + no_vec)
      end
    end
  end
end
```

참고: `FunctionLogger`는 기존 `Articles::Query`가 `extend`하는 모듈로 `logger`를 제공한다.
`Digest`는 Rails 환경에서 로드되어 있다.

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/functions/articles/hybrid_search_test.rb`
Expected: PASS (5 runs, 0 failures)

문제 시: `nearest_neighbors`가 `:neighbor_distance`를 pluck하지 못하면 neighbor 버전 차이다.
`.pluck(:id, :neighbor_distance)` 대신 `.select(:id).map { [it.id, it.neighbor_distance] }`로 대체.

- [ ] **Step 5: Commit**

```bash
git add app/functions/articles/hybrid_search.rb test/functions/articles/hybrid_search_test.rb
git commit -m "Add Articles::HybridSearch orchestrator"
```

---

### Task 5: 메인 검색 연결 (Articles::Query + 컨트롤러)

**Files:**
- Modify: `app/functions/articles/query.rb`
- Modify: `app/controllers/articles_controller.rb:27`
- Test: `test/functions/articles/query_test.rb`

검색 분기를 HybridSearch ID → `in_order_of`로 교체하고, `published_at` 정렬 책임을
컨트롤러에서 Query의 비검색 분기로 옮긴다(검색 결과의 RRF 순서가 덮이지 않도록).

- [ ] **Step 1: Test list — add ONE test at a time (Canon TDD), Red→Green each before the next**

```ruby
# test/functions/articles/query_test.rb
# frozen_string_literal: true

require "test_helper"

class Articles::QueryTest < ActiveSupport::TestCase
  test "search branch returns articles in hybrid rank order" do
    a = articles(:ruby_article)
    Articles::HybridSearch.stub(:call, [a.id]) do
      result = Articles::Query.index_html("Ruby")
      assert_equal [a.id], result.map(&:id)
    end
  end

  test "search branch with empty hybrid result is an empty relation" do
    Articles::HybridSearch.stub(:call, []) do
      assert_empty Articles::Query.index_html("nope").to_a
    end
  end

  test "non-search branch is ordered by published_at desc" do
    result = Articles::Query.index_html(nil).to_a
    published = result.map(&:published_at).compact
    assert_equal published.sort.reverse, published
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/functions/articles/query_test.rb`
Expected: FAIL — non-search 정렬 미적용 또는 search 분기가 FTS 스코프를 반환해 stub이 무시됨

- [ ] **Step 3: Edit `app/functions/articles/query.rb`**

`index_html` 과 `index_scope` 를 아래로 교체한다.

```ruby
      def index_html(search = nil)
        scope = index_scope(search)
        return scope if search.present?

        scope.where.not(id: excluded_related_article_ids(base_scope.related))
             .order(published_at: :desc)
      end
```

```ruby
      def index_scope(search)
        if search.present?
          ids = Articles::HybridSearch.call(query: search, limit: Articles::HybridSearch::CANDIDATE_POOL)
          base_scope.where(id: ids).in_order_of(:id, ids)
                    .includes(*DEFAULT_INCLUDES).without_toast
        else
          base_scope.related.includes(*DEFAULT_INCLUDES).without_toast
        end
      end
```

- [ ] **Step 4: Edit `app/controllers/articles_controller.rb:27`**

검색 시 `.order(published_at:)`를 적용하지 않는다(Query가 정렬을 책임진다).

```ruby
    @pagy, @articles = pagy(Articles::Query.index_html(search))
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/functions/articles/query_test.rb`
Expected: PASS (3 runs, 0 failures)

- [ ] **Step 6: Validate edited files**

Run: `bin/rails 'ai:tool[validate]' files=app/functions/articles/query.rb,app/controllers/articles_controller.rb level=rails`
Expected: no errors (missing partials/bad column refs 없음)

- [ ] **Step 7: Commit**

```bash
git add app/functions/articles/query.rb app/controllers/articles_controller.rb test/functions/articles/query_test.rb
git commit -m "Wire hybrid search into main article search"
```

---

### Task 6: 에이전트 도구 query 경로 연결

**Files:**
- Modify: `app/tools/search_related_articles.rb:59-65`

`search_by_text`를 HybridSearch(`mmr: true`)로 교체한다. `article_id` 경로(`search_by_embedding`)는
기존 벡터 NN을 유지한다. (`app/tools/`는 커버리지 제외 대상이라 별도 테스트 불필요 —
검색 로직은 Task 4에서 검증됨.)

- [ ] **Step 1: Edit `app/tools/search_related_articles.rb`**

`search_by_text` 메서드를 아래로 교체한다.

```ruby
  def search_by_text(query, limit)
    ids = Articles::HybridSearch.call(query:, limit:, mmr: true)
    Article.kept.confirmed.where(id: ids).in_order_of(:id, ids)
           .select(:id, :title_ko, :slug, :summary_key)
           .map { format_result(it) }
  end
```

- [ ] **Step 2: Validate**

Run: `bin/rails 'ai:tool[validate]' files=app/tools/search_related_articles.rb level=rails`
Expected: no errors

- [ ] **Step 3: Sanity-check the tool path in console (optional)**

Run:
```bash
bin/rails runner 'puts SearchRelatedArticles.new.execute(query: "Ruby", limit: 3).inspect'
```
Expected: 배열 형태의 결과(또는 빈 배열). 예외 없이 종료.

- [ ] **Step 4: Commit**

```bash
git add app/tools/search_related_articles.rb
git commit -m "Use hybrid search for SearchRelatedArticles query path"
```

---

### Task 7: 전체 검증

- [ ] **Step 1: Run the full related test directories**

Run: `bin/rails test test/functions/search test/functions/articles`
Expected: 모든 테스트 PASS

- [ ] **Step 2: Run the full suite**

Run: `bin/rails test`
Expected: 0 failures, 0 errors (기존 통과 테스트 회귀 없음)

- [ ] **Step 3: RBS/품질 게이트 (있으면)**

Run: `bin/rails test` 후 `rake quality` (커버리지+Flog 게이트). 신규 순수 함수는 커버리지 충족.
Expected: 게이트 통과. 미달 시 누락 분기 테스트 추가.

---

## Self-Review 결과

- **스펙 커버리지:** 임베딩 캐시·폴백(Task4 query_embedding), 벡터검색(Task4 vector_search), FTS(Task4 fts_search), RRF(Task2), 임계값(Task4 threshold_filter), MMR(Task3, Task4 rerank), 메인검색 연결(Task5), 에이전트 도구(Task6) — 스펙 전 섹션 매핑 완료.
- **거리 메트릭:** 인덱스 euclidean 유지, 코사인은 Ruby(Task1) — 스펙과 일치.
- **타입 일관성:** `Search::VectorMath.cosine_similarity`, `Search::ReciprocalRankFusion.call`, `Search::MaximalMarginalRelevance.call(query_vector:, candidates:, lambda:, limit:)`, `Articles::HybridSearch.call(query:, limit:, mmr:)` — Task 간 시그니처 동일.
- **상수:** `CANDIDATE_POOL=100`을 메인 검색 limit(=페이지네이션 상한)으로 재사용 — 스펙의 `HYBRID_LIMIT == CANDIDATE_POOL` 반영.
- **플레이스홀더:** 없음. 모든 코드/명령 구체화됨.
