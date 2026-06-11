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

  test "size mismatch yields 0.0" do
    assert_equal 0.0, Search::VectorMath.cosine_similarity([1.0, 2.0], [1.0])
  end
end

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
    result = Search::ReciprocalRankFusion.call([[1, 2], [2, 3]], k: 1_000_000)
    assert_includes result, 1
    assert_includes result, 2
    assert_includes result, 3
  end
end

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
