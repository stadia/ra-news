# frozen_string_literal: true
# rbs_inline: enabled

module Search
  class << self
    # ── VectorMath ────────────────────────────────────────────────
    #: (Array[Float]? a, Array[Float]? b) -> Float
    def cosine_similarity(a, b)
      return 0.0 if a.blank? || b.blank? || a.size != b.size

      dot = 0.0
      norm_a = 0.0
      norm_b = 0.0
      # 고차원(1536) 벡터에서 블록 호출 오버헤드를 피하려 while 루프 사용.
      # .to_f 는 정수 등 비-Float 입력에도 안전하도록 유지한다(범용 유틸).
      i = 0
      len = a.size
      while i < len
        av = a[i].to_f
        bv = b[i].to_f
        dot += av * bv
        norm_a += av * av
        norm_b += bv * bv
        i += 1
      end
      return 0.0 if norm_a.zero? || norm_b.zero?

      dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
    end

    # ── ReciprocalRankFusion ──────────────────────────────────────
    DEFAULT_K = 60

    # 여러 순위 ID 리스트를 RRF 점수로 병합한다. 점수 정규화 없이 순위만 사용한다.
    # score(id) = Σ_over_lists 1.0 / (k + rank), rank는 0부터.
    #: (Array[Array[Integer]] ranked_lists, ?k: Integer) -> Array[Integer]
    def fuse(ranked_lists, k: DEFAULT_K)
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

      scores.keys.sort_by { |id| [ -scores[id], first_seen[id] ] }
    end

    # ── MaximalMarginalRelevance ──────────────────────────────────
    # 관련도(쿼리 유사도)와 다양성(선택된 후보와의 비유사도)의 균형으로 재순위한다.
    # 매 단계 argmax: λ·cos(query, d) − (1−λ)·max_{s∈selected} cos(d, s)
    #: (query_vector: Array[Float], candidates: Array[Hash[Symbol, untyped]], lambda: Float, limit: Integer) -> Array[untyped]
    def rerank(query_vector:, candidates:, lambda:, limit:)
      remaining = candidates.dup
      selected = []
      # 선택된 후보들과의 최대 코사인 유사도(diversity penalty)를 incremental 하게 유지한다.
      # 매 단계 새로 선택된 후보 1개와의 유사도만 비교하면 되어 O(K·N)으로 동작한다.
      max_sim_to_selected = {}

      query_sim = remaining.to_h do |c|
        [ c[:id], cosine_similarity(query_vector, c[:vector]) ]
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
          sim = cosine_similarity(c[:vector], best[:vector])
          current = max_sim_to_selected[c[:id]]
          max_sim_to_selected[c[:id]] = current && current > sim ? current : sim
        end
      end

      selected.map { |c| c[:id] }
    end
  end
end
