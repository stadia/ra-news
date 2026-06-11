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
      # 선택된 후보들과의 최대 코사인 유사도(diversity penalty)를 incremental 하게 유지한다.
      # 매 단계 새로 선택된 후보 1개와의 유사도만 비교하면 되어 O(K·N)으로 동작한다.
      max_sim_to_selected = {}

      query_sim = remaining.to_h do |c|
        [ c[:id], Search::VectorMath.cosine_similarity(query_vector, c[:vector]) ]
      end

      until remaining.empty? || selected.size >= limit
        best =
          if selected.empty?
            remaining.max_by { |c| query_sim[c[:id]] }
          else
            remaining.max_by do |c|
              diversity_penalty = max_sim_to_selected[c[:id]]
              mmr_score = (lambda * query_sim[c[:id]]) - ((1 - lambda) * diversity_penalty)
              # 동점 시 다양성(낮은 diversity_penalty) 우선
              [ mmr_score, -diversity_penalty ]
            end
          end

        selected << best
        remaining.delete(best)

        remaining.each do |c|
          sim = Search::VectorMath.cosine_similarity(c[:vector], best[:vector])
          current = max_sim_to_selected[c[:id]]
          max_sim_to_selected[c[:id]] = current && current > sim ? current : sim
        end
      end

      selected.map { |c| c[:id] }
    end
  end
end
