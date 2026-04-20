# frozen_string_literal: true

require "test_helper"

class DiscordArticleDeliveryJobTest < ActiveJob::TestCase
  test "전송 기록 저장에 실패하면 예외를 발생시켜 재시도 가능 상태로 남긴다" do
    article = articles(:ruby_article)
    channel = notification_channels(:acme_discord)
    delivery = DiscordDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: "al-news",
      status: :failed
    )

    fake_client = Struct.new(:response) do
      def post_embed(embed_params)
        response
      end
    end.new("msg-123")

    DiscordClient.stub(:new, fake_client) do
      job = DiscordArticleDeliveryJob.new
      job.stub(:persist_delivery_success, ->(actual_delivery, _c, _m) {
        actual_delivery.errors.add(:base, "test")
        raise ActiveRecord::RecordInvalid, actual_delivery
      }) do
        error = assert_raises(ActiveRecord::RecordInvalid) do
          job.perform(article.id, channel.id)
        end

        assert_equal delivery.id, error.record.id
      end
    end
  end

  test "전송 실패 처리 중 이미 sent 상태면 failed로 되돌리지 않는다" do
    article = articles(:ruby_article)
    channel = notification_channels(:acme_discord)
    delivery = Class.new do
      attr_reader :update_called

      def initialize
        @sent = false
        @update_called = false
      end

      def with_lock
        yield
      end

      def sent?
        @sent
      end

      def reload
        @sent = true
      end

      def update!(**)
        @update_called = true
      end
    end.new

    DiscordClient.stub(:new, Struct.new(:error) {
      def post_embed(embed_params)
        raise error
      end
    }.new(DiscordClient::ApiError.new("timeout"))) do
      job = DiscordArticleDeliveryJob.new
      job.stub(:find_or_create_delivery, delivery) do
        job.perform(article.id, channel.id)
      end
    end

    assert_predicate delivery, :sent?
    refute delivery.update_called
  end

  test "신규 delivery의 기본 상태는 failed다" do
    delivery = DiscordDelivery.create!(
      article: articles(:ruby_article),
      notification_channel: notification_channels(:acme_discord),
      channel_id: "DCDEFAULT1",
      channel_name: "al-news"
    )

    assert_predicate delivery, :failed?
  end
end
