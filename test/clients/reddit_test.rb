# frozen_string_literal: true

require "test_helper"

class RedditTest < ActiveSupport::TestCase
  test "Reddit은 ApplicationClient를 상속한다" do
    assert_operator Reddit, :<, ApplicationClient
  end

  test "Reddit은 feed 메서드를 가진다" do
    assert Reddit.method_defined?(:feed)
  end
end
