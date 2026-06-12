# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module HybridSearch
    extend FunctionLogger

    # 튜닝 파라미터는 config/hybrid_search.yml 에서 환경별로 로드한다.
    # 부팅 초기(마이그레이션·에셋 프리컴파일 등)에 Rails.application 이 없을 수 있어 방어한다.
    config =
      if defined?(Rails) && Rails.application
        Rails.application.config_for(:hybrid_search)
      else
        {}
      end

    CANDIDATE_POOL = config.fetch(:candidate_pool, 100)
    RRF_K = config.fetch(:rrf_k, 60)
    COSINE_THRESHOLD = config.fetch(:cosine_threshold, 0.6)
    MMR_LAMBDA = config.fetch(:mmr_lambda, 0.7)
    EMBED_CACHE_TTL = config.fetch(:embed_cache_ttl, 43200).seconds
    # 임베딩 모델/차원은 embedding 컬럼(halfvec 3072)·스키마와 결합돼 있어 하드코딩 유지한다.
    EMBED_MODEL = "gemini-embedding-2"
    EMBED_DIMENSIONS = 3072

    class << self
      #: (query: String, ?limit: Integer, ?mmr: bool) -> Array[Integer]
      def run(query:, limit: 20, mmr: false)
        term = query.to_s.strip
        return [] if term.blank?

        qvec = query_embedding(term)
        vector_ids = qvec ? vector_search(qvec) : []
        fts_ids = fts_search(term)

        fused = Articles::Search.fuse([ vector_ids, fts_ids ], k: RRF_K)
        return fused.first(limit) if fused.empty? || qvec.nil?

        vectors = candidate_vectors(fused)
        kept = threshold_filter(fused, vectors, qvec, fts_ids)
        ranked = mmr ? rerank(kept, vectors, qvec, limit) : kept
        ranked.first(limit)
      end

      private

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

      # 후보 선정은 embedding의 HNSW 인덱스(halfvec_cosine_ops)에 맞춰 cosine 거리로 한다.
      # threshold_filter / rerank 도 cosine 기준이라 검색~필터~재랭킹이 동일 기준으로 일관된다.
      # RRF는 순위만 사용하므로 neighbor_distance 값 자체는 필요 없다.
      #: (Array[Float] qvec) -> Array[Integer]
      def vector_search(qvec)
        Article.kept.confirmed
               .nearest_neighbors(:embedding, qvec, distance: "cosine")
               .limit(CANDIDATE_POOL)
               .select(:id)
               .map(&:id)
      end

      #: (String term) -> Array[Integer]
      def fts_search(term)
        Article.kept.confirmed.full_text_search_for(term).limit(CANDIDATE_POOL).pluck(:id)
      end

      #: (Array[Integer] ids) -> Hash[Integer, Array[Float]]
      def candidate_vectors(ids)
        Article.where(id: ids).where.not(embedding: nil)
               .select(:id, :embedding)
               .to_h { |a| [ a.id, a.embedding.to_a ] }
      end

      #: (Array[Integer] fused, Hash[Integer, Array[Float]] vectors, Array[Float] qvec, Array[Integer] fts_ids) -> Array[Integer]
      def threshold_filter(fused, vectors, qvec, fts_ids)
        fts_set = fts_ids.to_set
        fused.select do |id|
          next true if fts_set.include?(id)

          vec = vectors[id]
          vec && Articles::Search.cosine_similarity(qvec, vec) >= COSINE_THRESHOLD
        end
      end

      # MMR은 limit 개까지만 선택하면 충분하다. no_vec(임베딩 없는 FTS 후보)는 항상 뒤에 붙고
      # 호출부의 first(limit)이 절단하므로, MMR을 limit 으로 제한해도 결과는 동일하며 연산만 줄어든다.
      #: (Array[Integer] ids, Hash[Integer, Array[Float]] vectors, Array[Float] qvec, Integer limit) -> Array[Integer]
      def rerank(ids, vectors, qvec, limit)
        candidates = ids.filter_map do |id|
          vec = vectors[id]
          { id: id, vector: vec } if vec
        end
        no_vec = ids - candidates.map { |c| c[:id] }
        reranked = Articles::Search.rerank(
          query_vector: qvec, candidates: candidates, lambda: MMR_LAMBDA, limit: limit
        )
        reranked + no_vec
      end
    end
  end
end
