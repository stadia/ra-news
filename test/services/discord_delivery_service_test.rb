# frozen_string_literal: true

require "test_helper"

class DiscordDeliveryServiceTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
    @channel = notification_channels(:acme_discord)
    DiscordDelivery.where(article: @article, notification_channel: @channel).delete_all
  end

  test "전송 성공 시 delivery 상태가 sent로 변경된다" do
    fake_client = Object.new
    def fake_client.post_embed(embed_params)
      "msg-123"
    end

    DiscordClient.stub(:new, ->(_c) { fake_client }) do
      result = DiscordDeliveryService.new.call(@article, @channel)

      assert_predicate result, :success?

      delivery = DiscordDelivery.find_by(article: @article, notification_channel: @channel)

      assert_predicate delivery, :sent?
      assert_equal "msg-123", delivery.message_id
    end
  end

  test "전송 실패 시 delivery 상태가 failed이고 에러 메시지가 저장된다" do
    fake_client = Object.new
    def fake_client.post_embed(embed_params)
      raise DiscordClient::ApiError, "timeout"
    end

    DiscordClient.stub(:new, ->(_c) { fake_client }) do
      result = DiscordDeliveryService.new.call(@article, @channel)

      assert_predicate result, :failure?

      delivery = DiscordDelivery.find_by(article: @article, notification_channel: @channel)

      assert_predicate delivery, :failed?
      assert_equal "timeout", delivery.error_message
    end
  end

  test "이미 sent 상태의 delivery는 재전송하지 않는다" do
    DiscordDelivery.create!(
      article: @article,
      notification_channel: @channel,
      channel_id: @channel.channel_id,
      channel_name: @channel.channel_name,
      status: :sent,
      sent_at: Time.current,
      message_id: "existing-msg"
    )

    DiscordClient.stub(:new, ->(_c) { raise "should not be called" }) do
      result = DiscordDeliveryService.new.call(@article, @channel)

      assert_predicate result, :failure?
      assert_equal :already_sent, result.failure
    end
  end

  test "신규 delivery의 기본 상태는 failed다" do
    delivery = DiscordDelivery.create!(
      article: @article,
      notification_channel: @channel,
      channel_id: "DCDEFAULT1",
      channel_name: "al-news"
    )

    assert_predicate delivery, :failed?
  end
end
