# frozen_string_literal: true

require "test_helper"

class YoutubeSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueue_all이 Site.kept.youtube의 ID를 예약한다" do
    assert_enqueued_with(job: YoutubeSiteJob, args: [Site.kept.youtube.order("id ASC").pluck(:id)]) do
      YoutubeSiteJob.enqueue_all
    end
  end

  test "YOUTUBE_NORMALIZED_HOST가 www.youtube.com이다" do
    assert_equal "www.youtube.com", YoutubeSiteJob::YOUTUBE_NORMALIZED_HOST
  end
end