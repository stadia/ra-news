# frozen_string_literal: true

require "test_helper"

class NotificationChannelTest < ActiveSupport::TestCase
  test "delivery_ready는 discarded channel을 제외한다" do
    channel = notification_channels(:acme_discord)
    channel.discard

    assert_not_includes NotificationChannel.active, channel
    assert_not_includes NotificationChannel.delivery_ready, channel
  end

  test "delivery가 있는 channel은 destroy할 수 없다" do
    channel = notification_channels(:acme_slack)

    assert_not channel.destroy
    assert_predicate channel.errors[:base], :any?
  end
end
