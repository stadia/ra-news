# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module SearchBenchmark
  module_function

  # Mean Reciprocal Rank — 평균 역순위.
  # 여러 쿼리의 ranked_list 와 relevant_ids 쌍에 대해 MRR을 계산한다.
  # 각 쿼리의 정답은 단일 ID 또는 Array 모두 허용한다. 정답이 여러 개일 때는
  # 결과에서 가장 먼저 등장하는 정답의 rank 역수를 사용한다(표준 MRR 정의).
  #: (Array[Array[Integer]] ranked_lists, Array[untyped] relevant_ids_list) -> Float
  def mrr(ranked_lists, relevant_ids_list)
    return 0.0 if ranked_lists.empty? || relevant_ids_list.empty?

    sum = ranked_lists.zip(relevant_ids_list).sum do |ranked, relevant|
      ids = Array(relevant).to_set
      rank = ranked.find_index { |id| ids.include?(id) }
      rank ? 1.0 / (rank + 1) : 0.0
    end

    sum / ranked_lists.size
  end

  # Normalized Discounted Cumulative Gain @ k.
  # Binary relevance: id가 ideal_ranking에 존재하면 relevant=1, 아니면 0.
  # DCG = Σ (2^rel - 1) / log2(i + 2)  (i=0부터)
  #: (Array[Array[Integer]] ranked_lists, Array[Array[Integer]] ideal_rankings, ?k: Integer) -> Float
  def ndcg_at(ranked_lists, ideal_rankings, k: 10)
    return 0.0 if ranked_lists.empty? || ideal_rankings.empty?

    sum = ranked_lists.zip(ideal_rankings).sum do |ranked, ideal|
      ideal_set = ideal.to_set
      dcg = ranked.first(k).each_with_index.sum do |id, i|
        ideal_set.include?(id) ? 1.0 / Math.log2(i + 2) : 0.0
      end
      # IDCG: ideal_set 항목들이 모두 상위에 정렬된 경우
      n_ideal = [ ideal_set.size, k ].min
      idcg = (0...n_ideal).sum { |i| 1.0 / Math.log2(i + 2) }
      idcg.zero? ? 0.0 : dcg / idcg
    end

    sum / ranked_lists.size
  end

  # Recall @ k — 전체 relevant 중 상위 k개 내에서 찾은 비율.
  #: (Array[Array[Integer]] ranked_lists, Array[Array[Integer]] relevant_ids_list, ?k: Integer) -> Float
  def recall_at(ranked_lists, relevant_ids_list, k: 10)
    return 0.0 if ranked_lists.empty? || relevant_ids_list.empty?

    sum = ranked_lists.zip(relevant_ids_list).sum do |ranked, relevant|
      relevant_set = relevant.to_set
      next 0.0 if relevant_set.empty?

      found = ranked.first(k).count { |id| relevant_set.include?(id) }
      found.to_f / relevant_set.size
    end

    sum / ranked_lists.size
  end
end
