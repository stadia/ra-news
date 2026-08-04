# typed: true
# frozen_string_literal: true

require "test_helper"

class ArticleBatchJobTest < ActiveSupport::TestCase
  test "배치 처리 후 전체 multisearch 재빌드를 호출하지 않는다" do
    article = articles(:site_only_article)
    created_at = 1.day.from_now
    article.update_columns(title_ko: nil, created_at:)

    called_articles = []
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |record|
      called_articles << record
      record.update!(title_ko: "배치 요약 결과", summary_key: [ "요약" ])
      Struct.new(:success?).new(true)
    end

    PgSearch::Multisearch.stub(:rebuild, ->(*, **_) { raise "should not be called" }) do
      ArticleAgentsService.stub(:new, -> { fake_service }) do
        job = ArticleBatchJob.new
        job.stub(:check_rate_limit, true) do
          job.stub(:sleep, nil) do
            job.perform(1.hour.from_now)
          end
        end
      end
    end

    assert_equal [ article ], called_articles
  end
end
