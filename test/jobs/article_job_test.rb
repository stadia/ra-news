# frozen_string_literal: true

require "test_helper"

class ArticleJobTest < ActiveSupport::TestCase
  test "기사 처리 후 전체 multisearch 재빌드를 호출하지 않는다" do
    article = articles(:ruby_article)
    called_article = nil
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |record|
      called_article = record
    end

    PgSearch::Multisearch.stub(:rebuild, ->(*, **_) { raise "should not be called" }) do
      ArticleAgentsService.stub(:new, -> { fake_service }) do
        ArticleJob.perform_now(article.id)
      end
    end

    assert_equal article, called_article
  end
end
