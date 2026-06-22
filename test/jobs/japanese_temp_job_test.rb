# frozen_string_literal: true

require "test_helper"

class JapaneseTempJobTest < ActiveSupport::TestCase
  test "title이 nil인 article도 에러 없이 처리한다" do
    article = articles(:ruby_article)
    article.update_columns(title: nil, title_ja: nil)

    fake_service = Object.new
    fake_service.define_singleton_method(:run_japanese) { |*| nil }

    job = JapaneseTempJob.new
    job.stub(:run_similar, nil) do
      ArticleAgentsService.stub(:new, fake_service) do
        JapaneseTempJob.stub(:new, job) do
          assert_nothing_raised { JapaneseTempJob.perform_now }
        end
      end
    end
  end

  test "처리할 article이 없으면 조용히 종료한다" do
    Article.kept.confirmed.where(title_ja: nil).update_all(title_ja: "dummy")

    assert_nothing_raised { JapaneseTempJob.perform_now }
  end
end
