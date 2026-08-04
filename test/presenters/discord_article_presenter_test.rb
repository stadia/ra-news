# typed: false
# frozen_string_literal: true

require "test_helper"

class DiscordArticlePresenterTest < ActiveSupport::TestCase
  test "embed_params가 올바른 Discord embed 형식을 반환한다" do
    article = articles(:ruby_article)
    presenter = DiscordArticlePresenter.new(article)

    params = presenter.embed_params

    assert_predicate params[:title], :present?
    assert_match %r{/articles/}, params[:url]
    assert_equal 3447003, params[:color]
    assert_equal article.site.name, params[:footer_text]
    assert_equal article.created_at, params[:timestamp]
  end

  test "title_ko가 없으면 title을 사용한다" do
    article = articles(:ruby_article)
    article.title_ko = nil
    presenter = DiscordArticlePresenter.new(article)

    assert_equal article.title, presenter.embed_params[:title]
  end
end
