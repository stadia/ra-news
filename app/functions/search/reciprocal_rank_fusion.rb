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
      ranks_per_id = Hash.new { |h, k| h[k] = [] }
      first_seen = {}
      order = 0

      ranked_lists.each do |list|
        next if list.blank?

        list.each_with_index do |id, rank|
          scores[id] += 1.0 / (k + rank)
          ranks_per_id[id] << rank
          unless first_seen.key?(id)
            first_seen[id] = order
            order += 1
          end
        end
      end

      scores.keys.sort_by do |id|
        ranks = ranks_per_id[id]
        mean = ranks.sum.to_f / ranks.size
        variance = ranks.map { |r| (r - mean) ** 2 }.sum / ranks.size
        consistency = variance.zero? ? Float::INFINITY : 1.0 / variance
        [-consistency, -scores[id], first_seen[id]]
      end
    end
  end
end
