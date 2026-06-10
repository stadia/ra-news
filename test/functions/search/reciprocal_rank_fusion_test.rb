# frozen_string_literal: true

require "test_helper"

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
