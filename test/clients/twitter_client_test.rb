# typed: true
# frozen_string_literal: true

require "test_helper"

class TwitterClientTest < ActiveSupport::TestCase
  test "TwitterClient는 client 접근자를 가진다" do
    assert TwitterClient.method_defined?(:client) || TwitterClient.instance_methods.include?(:client)
  end

  test "TwitterClient는 post 메서드를 가진다" do
    assert TwitterClient.method_defined?(:post)
  end

  test "TwitterClient는 delete 메서드를 가진다" do
    assert TwitterClient.method_defined?(:delete)
  end

  test "OAuth 설정이 없으면 ArgumentError가 발생한다" do
    Preference.stub(:get_object, nil) do
      assert_raises(ArgumentError) { TwitterClient.new }
    end
  end
end
