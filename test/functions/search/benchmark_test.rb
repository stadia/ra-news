# typed: true
# frozen_string_literal: true

require "test_helper"

class SearchBenchmarkTest < ActiveSupport::TestCase
  test "mrr returns 1.0 when first result is relevant" do
    assert_in_delta 1.0, SearchBenchmark.mrr([ [ 1, 2, 3 ] ], [ 1 ]), 1e-9
  end

  test "mrr returns 1/rank when relevant at position N" do
    # relevant_id=3 is at position 3 (index 2) in the ranked list
    assert_in_delta 1.0 / 3, SearchBenchmark.mrr([ [ 1, 2, 3 ] ], [ 3 ]), 1e-9
  end

  test "mrr returns 0.0 when no relevant result found" do
    assert_in_delta(0.0, SearchBenchmark.mrr([ [ 1, 2 ] ], [ 5 ]))
  end

  test "mrr averages across multiple queries" do
    # query1: relevant at pos1 → 1.0, query2: relevant at pos2 → 0.5
    assert_in_delta 0.75, SearchBenchmark.mrr([ [ 10, 20 ], [ 30, 40 ] ], [ 10, 40 ]), 1e-9
  end

  test "mrr handles empty input gracefully" do
    assert_in_delta(0.0, SearchBenchmark.mrr([], []))
  end

  test "ndcg_at_k returns 1.0 for perfect ranking" do
    assert_in_delta 1.0, SearchBenchmark.ndcg_at([ [ 1, 2, 3 ] ], [ [ 1, 2, 3 ] ], k: 3), 1e-9
  end

  test "recall_at_k returns fraction of relevant found" do
    # 2 relevant total [1, 2], 1 found in ranked [1, 3]
    assert_in_delta 0.5, SearchBenchmark.recall_at([ [ 1, 3 ] ], [ [ 1, 2 ] ], k: 5), 1e-9
  end
end
