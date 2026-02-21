# frozen_string_literal: true

require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
  end

  test "유효한 속성이면 저장된다" do
    subscription = PushSubscription.new(
      user: @user,
      endpoint: "https://example.com/subscription/123",
      p256dh: "test_p256dh",
      auth: "test_auth"
    )

    assert_predicate subscription, :valid?
  end

  test "endpoint가 없으면 유효하지 않다" do
    subscription = PushSubscription.new(user: @user, p256dh: "key", auth: "auth")

    assert_not subscription.valid?
    assert_includes subscription.errors[:endpoint], "내용을 입력해 주세요"
  end

  test "endpoint는 고유해야 한다" do
    existing = push_subscriptions(:john_browser)

    duplicate = PushSubscription.new(
      user: users(:jane),
      endpoint: existing.endpoint,
      p256dh: "another",
      auth: "another"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], "이미 존재하는 값입니다"
  end
end
