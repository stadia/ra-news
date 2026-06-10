# frozen_string_literal: true
# rbs_inline: enabled

# HybridSearchService — Article 본문 코퍼스 대상 6단계 하이브리드 검색 (RAG 코어).
#
# 파이프라인:
#   1. embed_query        — 쿼리 임베딩 (캐싱)
#   2. fulltext_candidates — pg_search 전문검색 순위 리스트
#   3. vector_candidates   — neighbor cosine 벡터 검색 (id => cosine_similarity)
#   4. RRF                 — 두 순위 리스트를 Reciprocal Rank Fusion으로 병합
#   5. threshold filter    — cosine similarity 하한 필터
#   6. MMR rerank          — 관련성 vs 다양성 균형 재랭킹
#
# 후속 increment TODO (이번 범위 밖):
#   (a) cosine 정렬용 vector_cosine_ops HNSW 인덱스 추가 — 현재 인덱스는
#       vector_l2_ops(L2)라 distance: "cosine"은 인덱스를 못 타고 순차 스캔된다.
#   (b) 청킹 도입(ArticleChunk + 청크 단위 embedding) — 현재는 기사단위 1벡터.
#   (c) Phase 2 & 3 진짜 병렬화 — 현재는 DB 풀 안전을 위해 순차 실행.
class HybridSearchService < OperationService
  RRF_K = 60
  MMR_LAMBDA = 0.5
  VECTOR_CANDIDATES = 30
  FULLTEXT_CANDIDATES = 30
  SIMILARITY_THRESHOLD = 0.5 # cosine similarity 하한
  RESULT_LIMIT = 10

  EMBED_MODEL = "gemini-embedding-001"
  EMBED_DIMENSIONS = 1536

  #: (String query, ?limit: Integer) -> Dry::Monads::Result
  def call(query, limit: RESULT_LIMIT)
    query_vector = step embed_query(query)
    fulltext_ids = step fulltext_candidates(query)
    vector_result = step vector_candidates(query_vector)

    fused_ids = step fuse(fulltext_ids, vector_result[:ranked_ids])
    filtered_ids = step apply_threshold(fused_ids, vector_result[:similarities])
    step rerank(query_vector, filtered_ids, limit)
  end

  protected

  # Phase 1 — 쿼리 임베딩. 동일 쿼리 재임베딩을 막기 위해 캐싱한다.
  #: (String query) -> Dry::Monads::Result
  def embed_query(query)
    return Failure(:blank_query) if query.blank?

    cache_key = "hybrid_search:embed:#{Digest::SHA256.hexdigest(query)}"
    vector = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      RubyLLM.embed(query, model: EMBED_MODEL, dimensions: EMBED_DIMENSIONS).vectors.to_a
    end

    return Failure(:embedding_failed) if vector.blank?

    Success(vector)
  rescue StandardError => e
    logger.error "HybridSearchService embed_query failed: #{e.message}"
    Failure(:embedding_failed)
  end

  # Phase 2 — 전문검색 후보 순위 리스트 (0-based rank 순서의 id 배열).
  #: (String query) -> Dry::Monads::Result
  def fulltext_candidates(query)
    ids = Article.kept.confirmed
                 .full_text_search_for(query)
                 .limit(FULLTEXT_CANDIDATES)
                 .pluck(:id)
    Success(ids)
  rescue StandardError => e
    logger.error "HybridSearchService fulltext_candidates failed: #{e.message}"
    Failure(:fulltext_failed)
  end

  # Phase 3 — 벡터 후보. cosine 거리로 정렬하고, 각 id의 cosine_similarity를 보존한다.
  # 반환: { ranked_ids: Array<id> (거리 오름차순), similarities: { id => cosine_similarity } }
  #: (Array[Float] query_vector) -> Dry::Monads::Result
  def vector_candidates(query_vector)
    records = Article.kept.confirmed
                     .nearest_neighbors(:embedding, query_vector, distance: "cosine")
                     .limit(VECTOR_CANDIDATES)

    ranked_ids = []
    similarities = {}
    records.each do |record|
      ranked_ids << record.id
      # neighbor_distance는 cosine distance → cosine_similarity = 1 - distance
      similarities[record.id] = 1.0 - record.neighbor_distance.to_f
    end

    Success({ ranked_ids: ranked_ids, similarities: similarities })
  rescue StandardError => e
    logger.error "HybridSearchService vector_candidates failed: #{e.message}"
    Failure(:vector_failed)
  end

  # Phase 4 — Reciprocal Rank Fusion.
  #: (Array[untyped] fulltext_ids, Array[untyped] vector_ids) -> Dry::Monads::Result
  def fuse(fulltext_ids, vector_ids)
    fused = Articles::SearchRanking.reciprocal_rank_fusion(
      [fulltext_ids, vector_ids],
      k: RRF_K
    )
    return Failure(:no_candidates) if fused.empty?

    Success(fused)
  end

  # Phase 5 — cosine similarity 임계값 필터.
  # 결정: 벡터 후보에 없는 id는 cosine_similarity 정보가 없다(전문검색에만 잡힘).
  # 이런 id는 보수적으로 통과시키되 RRF 점수로만 평가한다 — 전문검색이 강하게 매칭한
  # 결과를 similarity 미상이라는 이유로 버리지 않기 위함. 벡터 후보에 있으면서
  # similarity < SIMILARITY_THRESHOLD 인 id만 제거한다.
  #: (Array[untyped] fused_ids, Hash[untyped, Float] similarities) -> Dry::Monads::Result
  def apply_threshold(fused_ids, similarities)
    filtered = fused_ids.reject do |id|
      similarities.key?(id) && similarities[id] < SIMILARITY_THRESHOLD
    end
    Success(filtered)
  end

  # Phase 6 — MMR 재랭킹. 이 단계에서만 후보 Article을 embedding 포함해 로드한다.
  # 최종적으로 정렬된 Article 레코드 배열을 반환한다 (kept.confirmed 유지).
  #: (Array[Float] query_vector, Array[untyped] candidate_ids, Integer limit) -> Dry::Monads::Result
  def rerank(query_vector, candidate_ids, limit)
    return Success([]) if candidate_ids.empty?

    # MMR에 필요한 embedding을 포함해 후보만 로드.
    records_by_id = Article.kept.confirmed
                           .where(id: candidate_ids)
                           .index_by(&:id)

    candidates = candidate_ids.filter_map do |id|
      record = records_by_id[id]
      next if record.nil? || record.embedding.blank?

      { id: id, embedding: record.embedding.to_a }
    end

    ordered_ids = Articles::SearchRanking.maximal_marginal_relevance(
      query_vector,
      candidates,
      lambda_param: MMR_LAMBDA,
      limit: limit
    )

    Success(ordered_ids.map { |id| records_by_id[id] })
  rescue StandardError => e
    logger.error "HybridSearchService rerank failed: #{e.message}"
    Failure(:rerank_failed)
  end
end
