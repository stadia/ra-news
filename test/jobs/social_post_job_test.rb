# typed: true
# frozen_string_literal: true

require "test_helper"

class SocialPostJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "SocialPostJob는 production 환경이 아니면 즉시 반환한다" do
    article = articles(:ruby_article)

    # non-production 환경에서는 아무것도 하지 않고 반환
    assert_no_enqueued_jobs only: SocialPostJob do
      perform_enqueued_jobs
      SocialPostJob.new.perform(article.id)
    end
  end

  test "SocialPostJob은 ApplicationJob을 상속한다" do
    assert_includes SocialPostJob.ancestors, ActiveJob::Base
  end

  test "rate_limit_threshold가 2다" do
    job = SocialPostJob.new

    assert_equal 2, job.rate_limit_threshold
  end

  test "rate_limit_window가 5분이다" do
    job = SocialPostJob.new

    assert_equal 5.minutes, job.rate_limit_window
  end
end
