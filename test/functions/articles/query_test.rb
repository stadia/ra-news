# frozen_string_literal: true

require "test_helper"

class Articles::QueryTest < ActiveSupport::TestCase
  test "search branch returns articles in hybrid rank order" do
    a = articles(:ruby_article)
    b = articles(:korean_content_article)
    Articles::HybridSearch.stub(:run, [b.id, a.id]) do
      result = Articles::Query.index_html("Ruby")
      assert_equal [b.id, a.id], result.map(&:id)
    end
  end

  test "index_json search uses FTS and does not call HybridSearch" do
    Articles::HybridSearch.stub(:run, ->(*) { raise "should not be called" }) do
      assert_nothing_raised { Articles::Query.index_json("Ruby").to_a }
    end
  end

  test "search branch with empty hybrid result is an empty relation" do
    Articles::HybridSearch.stub(:run, []) do
      assert_empty Articles::Query.index_html("nope").to_a
    end
  end

  test "non-search branch is ordered by published_at desc" do
    result = Articles::Query.index_html(nil).to_a
    published = result.map(&:published_at).compact
    assert_equal published.sort.reverse, published
  end
end
