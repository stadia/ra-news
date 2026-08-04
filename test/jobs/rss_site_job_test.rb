# typed: true
# frozen_string_literal: true

require "test_helper"

class RssSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueue_all이 Site.kept.rss의 ID를 예약한다" do
    assert_enqueued_with(job: RssSiteJob, args: [ Site.kept.rss.order("id ASC").pluck(:id) ]) do
      RssSiteJob.enqueue_all
    end
  end

  test "RssSiteJob은 RssHelper를 포함한다" do
    assert_includes RssSiteJob.ancestors, RssHelper
  end
end
