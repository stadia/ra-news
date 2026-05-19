# frozen_string_literal: true

require "test_helper"

class RedditTest < ActiveSupport::TestCase
  test "Reddit는 모듈이다" do
    assert_kind_of Module, Reddit
  end

  test "Reddit은 feed 싱글톤 메서드를 가진다" do
    assert_respond_to Reddit, :feed
  end

  test "BASE_URL 상수가 정의되어 있다" do
    assert_equal "https://www.reddit.com", Reddit::BASE_URL
  end

  test "SUBREDDIT 상수가 정의되어 있다" do
    assert_equal "ruby+rails", Reddit::SUBREDDIT
  end

  test "USER_AGENT 상수가 정의되어 있다" do
    assert_match(/ruby-news/, Reddit::USER_AGENT)
  end
end
