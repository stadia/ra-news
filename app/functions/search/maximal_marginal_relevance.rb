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
          mmr_score = (lambda * query_sim[c[:id]]) - ((1 - lambda) * diversity_penalty)
          # Tie-break by favoring higher diversity (lower diversity_penalty)
          [mmr_score, -diversity_penalty]
        end

        selected << best
        remaining.delete(best)
      end

      selected.map { |c| c[:id] }
    end
  end
end
