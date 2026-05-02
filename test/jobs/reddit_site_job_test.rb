# frozen_string_literal: true

require "test_helper"

class RedditSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "RedditSiteJob은 ApplicationJob을 상속한다" do
    assert_includes RedditSiteJob.ancestors, ActiveJob::Base
  end

  test "REDDIT_HOSTS 상수가 정의되어 있다" do
    expected_hosts = %w[reddit.com www.reddit.com old.reddit.com new.reddit.com redd.it v.redd.it i.redd.it preview.redd.it external-preview.redd.it rubygems.org]
    assert_equal expected_hosts, RedditSiteJob::REDDIT_HOSTS
  end

  test "external_link?가 Reddit 내부 도메인을 올바르게 식별한다" do
    job = RedditSiteJob.new

    # 외부 링크 (Reddit 내부 도메인이 아님)
    assert job.send(:external_link?, "https://example.com/article")
    assert job.send(:external_link?, "https://blog.rubyonrails.org/post")

    # Reddit 내부 도메인 (외부 링크가 아님)
    assert_not job.send(:external_link?, "https://www.reddit.com/r/ruby")
    assert_not job.send(:external_link?, "https://reddit.com/r/ruby")
    assert_not job.send(:external_link?, "https://old.reddit.com/r/ruby")
    assert_not job.send(:external_link?, "https://redd.it/abc123")
    assert_not job.send(:external_link?, "https://rubygems.org/gems/rails")

    # 빈 URL이나 nil
    assert_not job.send(:external_link?, "")
    assert_not job.send(:external_link?, nil)
  end

  test "external_link?가 잘못된 URL을 처리한다" do
    job = RedditSiteJob.new

    assert_not job.send(:external_link?, "not-a-url")
  end
end