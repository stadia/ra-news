# frozen_string_literal: true

require "test_helper"

class RubyConferenceTest < ActiveSupport::TestCase
  test "RubyConference가 정의되어 있다" do
    assert_kind_of Class, RubyConference
  end

  test "BASE_URI가 올바르다" do
    assert_equal "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main", RubyConference::BASE_URI
  end

  test "RubyConference는 conferences 메서드를 가진다" do
    assert RubyConference.method_defined?(:conferences)
  end

  test "RubyConference는 conferences_cached 메서드를 가진다" do
    assert RubyConference.method_defined?(:conferences_cached)
  end
end
