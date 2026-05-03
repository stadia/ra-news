# frozen_string_literal: true

require "test_helper"

class RedditTest < ActiveSupport::TestCase
  test "Reddit는 모듈이다" do
    assert_kind_of Module, Reddit
  end

  test "Reddit은 feed 싱글톤 메서드를 가진다" do
    assert_respond_to Reddit, :feed
  end
end
