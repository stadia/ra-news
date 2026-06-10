# frozen_string_literal: true

require "test_helper"

class Articles::SearchRankingTest < ActiveSupport::TestCase
  # --- Reciprocal Rank Fusion ---

  test "RRF는 단일 리스트의 순위를 1/(k+rank)로 점수화한다" do
    result = Articles::SearchRanking.reciprocal_rank_fusion([[10, 20, 30]], k: 60)

    assert_equal [10, 20, 30], result
  end

  test "RRF는 양쪽 리스트에 등장하는 id의 점수를 합산한다" do
    fulltext = [1, 2, 3]
    vector   = [3, 4, 1]

    # id=1: 1/60 + 1/62, id=3: 1/62 + 1/60 => 동일 합산 점수
    # id=2: 1/61, id=4: 1/61
    result = Articles::SearchRanking.reciprocal_rank_fusion([fulltext, vector], k: 60)

    # 양쪽 등장(1, 3)이 한쪽 등장(2, 4)보다 앞선다
    assert_equal [1, 3], result.first(2).sort
    assert_includes result, 2
    assert_includes result, 4
    assert_equal 4, result.size
  end

  test "RRF는 더 높은 순위(낮은 rank)에 더 큰 점수를 준다" do
    # a는 양쪽에서 1위, b는 양쪽에서 꼴찌
    result = Articles::SearchRanking.reciprocal_rank_fusion([%w[a b], %w[a b]], k: 60)

    assert_equal %w[a b], result
  end

  test "RRF 빈 입력은 빈 결과" do
    assert_empty Articles::SearchRanking.reciprocal_rank_fusion([[], []])
  end

  # --- cosine similarity ---

  test "동일 벡터의 cosine_similarity는 1.0" do
    vec = [1.0, 2.0, 3.0]
    assert_in_delta 1.0, Articles::SearchRanking.cosine_similarity(vec, vec), 1e-9
  end

  test "직교 벡터의 cosine_similarity는 0.0" do
    assert_in_delta 0.0, Articles::SearchRanking.cosine_similarity([1.0, 0.0], [0.0, 1.0]), 1e-9
  end

  test "영벡터나 빈 벡터는 0.0" do
    assert_equal 0.0, Articles::SearchRanking.cosine_similarity([0.0, 0.0], [1.0, 1.0])
    assert_equal 0.0, Articles::SearchRanking.cosine_similarity([], [1.0])
  end

  # --- MMR ---

  test "MMR은 관련성과 다양성을 균형 맞춰 중복을 회피한다" do
    query = [1.0, 0.0]
    # a, b는 거의 동일(중복). c는 다른 방향이지만 query와 어느정도 관련.
    candidates = [
      { id: :a, embedding: [1.0, 0.0] },
      { id: :b, embedding: [0.99, 0.01] },
      { id: :c, embedding: [0.6, 0.8] }
    ]

    # λ를 낮춰 다양성 항을 지배적으로 만든다 → b(a와 거의 동일)보다 c를 선호.
    result = Articles::SearchRanking.maximal_marginal_relevance(
      query, candidates, lambda_param: 0.3, limit: 2
    )

    # 첫 선택은 query와 가장 관련 높은 a. 두번째는 a와 거의 동일한 b 대신
    # 다양성을 주는 c를 선택해야 한다.
    assert_equal :a, result.first
    assert_equal :c, result.second
  end

  test "MMR lambda=1은 순수 관련성 순(다양성 무시)" do
    query = [1.0, 0.0]
    candidates = [
      { id: :a, embedding: [1.0, 0.0] },
      { id: :b, embedding: [0.99, 0.01] },
      { id: :c, embedding: [0.6, 0.8] }
    ]

    result = Articles::SearchRanking.maximal_marginal_relevance(
      query, candidates, lambda_param: 1.0, limit: 3
    )

    assert_equal %i[a b c], result
  end

  test "MMR은 limit개만 반환한다" do
    query = [1.0, 0.0]
    candidates = (1..5).map { |i| { id: i, embedding: [1.0, i / 10.0] } }

    result = Articles::SearchRanking.maximal_marginal_relevance(
      query, candidates, lambda_param: 0.5, limit: 3
    )

    assert_equal 3, result.size
  end

  test "MMR 빈 후보는 빈 결과" do
    assert_empty Articles::SearchRanking.maximal_marginal_relevance([1.0], [], limit: 5)
  end
end
