# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "GET show returns 200 with article title" do
    article = articles(:ruby_article)
    get article_path(article)
    assert_response :success
    assert_select "article"
    assert_select "h1", text: /#{Regexp.escape(article.title_ko)}/
  end
end
