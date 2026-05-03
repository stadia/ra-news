# frozen_string_literal: true

require "test_helper"

class RedditTest < ActiveSupport::TestCase
  test "Reddit가 정의되어 있다" do
    assert_kind_of Class, Reddit
  end

  test "Reddit은 feed 메서드를 가진다" do
    assert Reddit.method_defined?(:feed)
  end
end