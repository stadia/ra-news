# typed: true
# frozen_string_literal: true

require "test_helper"

class Articles::HybridSearchConfigTest < ActiveSupport::TestCase
  test "reads candidate_pool from config/hybrid_search.yml" do
    assert_equal 10, Articles::HybridSearch::CANDIDATE_POOL
  end

  test "reads rrf_k from config" do
    assert_equal 60, Articles::HybridSearch::RRF_K
  end

  test "reads cosine_threshold from config" do
    assert_in_delta 0.6, Articles::HybridSearch::COSINE_THRESHOLD, 1e-9
  end

  test "reads mmr_lambda from config" do
    assert_in_delta 0.7, Articles::HybridSearch::MMR_LAMBDA, 1e-9
  end

  test "reads embed_cache_ttl from config" do
    assert_equal 12.hours, Articles::HybridSearch::EMBED_CACHE_TTL
  end

  test "embed_model and embed_dimensions remain hardcoded" do
    assert_equal "gemini-embedding-2", Articles::HybridSearch::EMBED_MODEL
    assert_equal 3072, Articles::HybridSearch::EMBED_DIMENSIONS
  end
end
