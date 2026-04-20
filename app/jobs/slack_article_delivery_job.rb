# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find_by(id: article_id)
    channel = SlackChannel.find_by(id: channel_id)
    return unless article && channel&.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    delivery = find_or_create_delivery(article, channel)
    message = SlackArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      response = SlackClient.new(channel).post_message(
        text: message.text,
        blocks: message.blocks
      )

      persist_delivery_success(delivery, channel.channel_name, response["ts"])
    end
  rescue SlackClient::ApiError => e
    delivery&.with_lock do
      delivery.reload
      return if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end
  end

  private

  #: (SlackDelivery delivery, String channel_name, String? message_ts) -> void
  def persist_delivery_success(delivery, channel_name, message_ts)
    delivery.update!(
        channel_name:,
        status: :sent,
        sent_at: Time.current,
        error_message: nil,
        message_id: message_ts
      )
  end

  #: (Article article, SlackChannel channel) -> SlackDelivery
  def find_or_create_delivery(article, channel)
    existing_delivery = SlackDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return existing_delivery if existing_delivery

    SlackDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
  rescue ActiveRecord::RecordNotUnique
    SlackDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
  end
end
