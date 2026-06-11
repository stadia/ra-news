# frozen_string_literal: true

require "test_helper"

class Articles::QueryTest < ActiveSupport::TestCase
  test "search branch returns articles in hybrid rank order" do
    a = articles(:ruby_article)
    b = articles(:korean_content_article)
    Articles::HybridSearch.stub(:run, [ b.id, a.id ]) do
      result = Articles::Query.index_html("Ruby")

      assert_equal [ b.id, a.id ], result.map(&:id)
    end
  end

  test "index_json search delegates candidate set to HybridSearch" do
    called = false
    Articles::HybridSearch.stub(:run, ->(**) { called = true; [] }) do
      Articles::Query.index_json("Ruby").to_a
    end

    assert called, "index_json should source its candidate set from HybridSearch"
  end

  test "index_json search returns the hybrid candidate set" do
    a = articles(:ruby_article)
    Articles::HybridSearch.stub(:run, [ a.id ]) do
      result = Articles::Query.index_json("Ruby")

      assert_includes result.map(&:id), a.id
    end
  end

  test "index_json search with empty hybrid result is an empty relation" do
    Articles::HybridSearch.stub(:run, []) do
      assert_empty Articles::Query.index_json("nope").to_a
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
