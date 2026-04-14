# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find_by(id: article_id)
    channel = DiscordChannel.find_by(id: channel_id)
    return unless article && channel&.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    delivery = find_or_create_delivery(article, channel)
    presenter = DiscordArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      message_id = DiscordClient.new(channel).post_embed(presenter.embed_params)

      persist_delivery_success(delivery, channel.channel_name, message_id)
    end
  rescue DiscordClient::ApiError => e
    delivery&.with_lock do
      delivery.reload
      return if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end
  end

  private

  #: (DiscordDelivery delivery, String channel_name, String? message_id) -> void
  def persist_delivery_success(delivery, channel_name, message_id)
    delivery.update!(
      channel_name:,
      status: :sent,
      sent_at: Time.current,
      error_message: nil,
      message_id:
    )
  end

  #: (Article article, DiscordChannel channel) -> DiscordDelivery
  def find_or_create_delivery(article, channel)
    existing_delivery = DiscordDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return existing_delivery if existing_delivery

    DiscordDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
  rescue ActiveRecord::RecordNotUnique
    DiscordDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
  end
end
