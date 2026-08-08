# frozen_string_literal: true

require "test_helper"

class RssSitePageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueue_all이 Site.kept.rss_page의 ID를 예약한다" do
    assert_enqueued_with(job: RssSitePageJob, args: [ Site.kept.rss_page.order("id ASC").pluck(:id) ]) do
      RssSitePageJob.enqueue_all
    end
  end

  test "RssSitePageJob은 RssHelper와 LinkHelper를 포함한다" do
    assert_includes RssSitePageJob.ancestors, RssHelper
    assert_includes RssSitePageJob.ancestors, LinkHelper
  end

  test "빈 ID 배열은 오류 없이 종료한다" do
    assert_nothing_raised { RssSitePageJob.perform_now([]) }
  end
end
