# frozen_string_literal: true

require "test_helper"

class ArticleShowPresenterTest < ActiveSupport::TestCase
  test "published_at_label은 로케일 short 포맷을 사용한다" do
    article = articles(:ruby_article)
    presenter = ArticleShowPresenter.new(article)

    I18n.with_locale(:en) do
      assert_equal I18n.l(article.published_at, format: :short), presenter.published_at_label(:short)
    end
  end
end
