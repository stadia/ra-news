# frozen_string_literal: true

require "test_helper"

class Articles::SearchSuggestionsTest < ActiveSupport::TestCase
  test "returns empty array for blank query" do
    assert_equal [], Articles::SearchSuggestions.suggest("")
    assert_equal [], Articles::SearchSuggestions.suggest("   ")
    assert_equal [], Articles::SearchSuggestions.suggest(nil)
  end

  test "returns array of strings" do
    result = Articles::SearchSuggestions.suggest("Ruby")
    assert_kind_of Array, result
  end

  test "respects limit parameter by returning at most limit results" do
    result = Articles::SearchSuggestions.suggest("Ruby", limit: 2)
    assert result.size <= 2
  end

  test "returns unique titles without duplicates" do
    result = Articles::SearchSuggestions.suggest("Ruby")
    assert_equal result.uniq, result
  end
end
