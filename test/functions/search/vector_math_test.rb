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
