# frozen_string_literal: true

require "test_helper"

class SlackDeliveryServiceTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
    @channel = notification_channels(:acme_slack)
    SlackDelivery.where(article: @article, notification_channel: @channel).delete_all
  end

  test "전송 성공 시 delivery 상태가 sent로 변경된다" do
    fake_client = Object.new
    def fake_client.post_message(text:, blocks:)
      { "ts" => "123.456" }
    end

    SlackClient.stub(:new, ->(_c) { fake_client }) do
      result = SlackDeliveryService.new.call(@article, @channel)
      assert result.success?

      delivery = SlackDelivery.find_by(article: @article, notification_channel: @channel)
      assert_predicate delivery, :sent?
      assert_equal "123.456", delivery.message_id
    end
  end

  test "전송 실패 시 delivery 상태가 failed이고 에러 메시지가 저장된다" do
    fake_client = Object.new
    def fake_client.post_message(text:, blocks:)
      raise SlackClient::ApiError, "timeout"
    end

    SlackClient.stub(:new, ->(_c) { fake_client }) do
      result = SlackDeliveryService.new.call(@article, @channel)
      assert result.failure?

      delivery = SlackDelivery.find_by(article: @article, notification_channel: @channel)
      assert_predicate delivery, :failed?
      assert_equal "timeout", delivery.error_message
    end
  end

  test "이미 sent 상태의 delivery는 재전송하지 않는다" do
    SlackDelivery.create!(
      article: @article,
      notification_channel: @channel,
      channel_id: @channel.channel_id,
      channel_name: @channel.channel_name,
      status: :sent,
      sent_at: Time.current,
      message_id: "existing-ts"
    )

    # Client should never be called
    SlackClient.stub(:new, ->(_c) { raise "should not be called" }) do
      result = SlackDeliveryService.new.call(@article, @channel)
      assert result.failure?
      assert_equal :already_sent, result.failure
    end
  end

  test "신규 delivery의 기본 상태는 failed다" do
    delivery = SlackDelivery.create!(
      article: @article,
      notification_channel: @channel,
      channel_id: "CDEFAULT1",
      channel_name: "ruby-news"
    )

    assert_predicate delivery, :failed?
  end
end
