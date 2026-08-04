# typed: true
# frozen_string_literal: true

require "test_helper"

class YoutubeSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "YouTube API 쿼터 초과 오류는 job을 실패시키지 않는다" do
    error = youtube_quota_exceeded_error
    client = Object.new
    client.define_singleton_method(:videos) do
      raise error
    end

    site = Object.new
    site.define_singleton_method(:init_client) { client }

    site.define_singleton_method(:update) do |**|
      flunk "쿼터 초과 시 last_checked_at을 갱신하면 안 된다"
    end

    Site.stub(:find, site) do
      assert_no_enqueued_jobs do
        assert_nothing_raised do
          YoutubeSiteJob.perform_now([ 123, 456 ])
        end
      end
    end
  end

  test "enqueue_all이 Site.kept.youtube의 ID를 예약한다" do
    assert_enqueued_with(job: YoutubeSiteJob, args: [ Site.kept.youtube.order("id ASC").pluck(:id) ]) do
      YoutubeSiteJob.enqueue_all
    end
  end

  test "YOUTUBE_NORMALIZED_HOST가 www.youtube.com이다" do
    assert_equal "www.youtube.com", YoutubeSiteJob::YOUTUBE_NORMALIZED_HOST
  end

  private

  def youtube_quota_exceeded_error
    response_body = {
      "error" => {
        "code" => 429,
        "message" => "Quota exceeded",
        "errors" => [ { "reason" => "rateLimitExceeded" } ],
        "status" => "RESOURCE_EXHAUSTED"
      }
    }

    Yt::Errors::RequestError.new({ "response_body" => response_body }.to_json)
  end
end
