# typed: true
# frozen_string_literal: true

require "test_helper"

class MastodonClientTest < ActiveSupport::TestCase
  test "MastodonClient가 정의되어 있다" do
    assert_kind_of Class, MastodonClient
  end

  test "MastodonClient는 client 접근자를 가진다" do
    assert MastodonClient.method_defined?(:client) || MastodonClient.new.respond_to?(:client)
  end
end
