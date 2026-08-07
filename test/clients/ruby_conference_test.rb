# frozen_string_literal: true

require "test_helper"

class RubyConferenceTest < ActiveSupport::TestCase
  test "RubyConference는 모듈이다" do
    assert_kind_of Module, RubyConference
  end

  test "BASE_URL이 올바르다" do
    assert_equal "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main", RubyConference::BASE_URL
  end

  test "RubyConference는 conferences 싱글톤 메서드를 가진다" do
    assert_respond_to RubyConference, :conferences
  end

  test "RubyConference는 conferences_cached 싱글톤 메서드를 가진다" do
    assert_respond_to RubyConference, :conferences_cached
  end
end
