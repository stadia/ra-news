# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  # 하이브리드 검색용 순수 랭킹 함수 모음 (DB/외부호출 없음, 결정적).
  # Reciprocal Rank Fusion(RRF), Maximal Marginal Relevance(MMR), cosine similarity.
  module SearchRanking
    class << self
      # 두 개(이상)의 순위 리스트를 Reciprocal Rank Fusion으로 병합한다.
      # score(id) = Σ 1 / (k + rank)  (rank는 0-based)
      # 양쪽 리스트에 모두 등장하는 id는 두 항을 합산한다.
      #: (Array[Array[untyped]] ranked_lists, ?k: Integer) -> Array[untyped]
      def reciprocal_rank_fusion(ranked_lists, k: 60)
        scores = Hash.new(0.0)

        ranked_lists.each do |ranked_ids|
          ranked_ids.each_with_index do |id, rank|
            scores[id] += 1.0 / (k + rank)
          end
        end

        # 병합 점수 내림차순. 동점은 입력 안정성을 위해 첫 등장 순서를 유지한다.
        scores.sort_by { |_id, score| -score }.map(&:first)
      end

      # 두 벡터의 코사인 유사도. 한쪽이라도 영벡터면 0.0.
      #: (Array[Float] vec_a, Array[Float] vec_b) -> Float
      def cosine_similarity(vec_a, vec_b)
        return 0.0 if vec_a.blank? || vec_b.blank?

        dot = 0.0
        norm_a = 0.0
        norm_b = 0.0
        vec_a.each_with_index do |a, i|
          b = vec_b[i].to_f
          dot += a * b
          norm_a += a * a
          norm_b += b * b
        end

        return 0.0 if norm_a.zero? || norm_b.zero?

        dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
      end

      # Maximal Marginal Relevance 재랭킹.
      # 각 후보는 { id:, embedding: } 형태. query_vector 대비 관련성과
      # 이미 선택된 결과 대비 다양성을 lambda로 균형한다.
      #   score = λ·sim(query, doc) − (1−λ)·max sim(doc, selected)
      # 입력 순서(보통 RRF 점수 내림차순)를 첫 선택 tie-break로 사용한다.
      # 반환: 선택된 순서의 id 배열 (최대 limit개).
      #: (Array[Float] query_vector, Array[Hash[Symbol, untyped]] candidates, ?lambda_param: Float, ?limit: Integer) -> Array[untyped]
      def maximal_marginal_relevance(query_vector, candidates, lambda_param: 0.5, limit: 10)
        return [] if candidates.blank?

        # 쿼리 대비 관련성을 미리 계산 (id => sim)
        remaining = candidates.dup
        relevance = remaining.to_h { |c| [c[:id], cosine_similarity(query_vector, c[:embedding])] }
        embeddings = remaining.to_h { |c| [c[:id], c[:embedding]] }

        selected = []

        while selected.any? ? (selected.size < limit && remaining.any?) : remaining.any?
          break if selected.size >= limit

          best = remaining.max_by do |cand|
            id = cand[:id]
            diversity =
              if selected.empty?
                0.0
              else
                selected.map { |sel_id| cosine_similarity(embeddings[id], embeddings[sel_id]) }.max
              end
            (lambda_param * relevance[id]) - ((1 - lambda_param) * diversity)
          end

          selected << best[:id]
          remaining.delete(best)
        end

        selected
      end
    end
  end
end
