# frozen_string_literal: true

require "test_helper"

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
