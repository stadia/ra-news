# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordDeliveryService < OperationService
  #: (Article article, DiscordChannel channel) -> Dry::Monads::Result
  def call(article, channel)
    delivery = step find_or_create_delivery(article, channel)
    step send_message(article, channel, delivery:)
  end

  private

  #: (Article article, DiscordChannel channel) -> Dry::Monads::Result
  def find_or_create_delivery(article, channel)
    existing = DiscordDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return Success(existing) if existing

    delivery = DiscordDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
    Success(delivery)
  rescue ActiveRecord::RecordNotUnique
    delivery = DiscordDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    Success(delivery)
  end

  #: (Article article, DiscordChannel channel, delivery: DiscordDelivery) -> Dry::Monads::Result
  def send_message(article, channel, delivery:)
    presenter = DiscordArticlePresenter.new(article)

    delivery.with_lock do
      return Failure(:already_sent) if delivery.sent?

      message_id = DiscordClient.new(channel).post_embed(presenter.embed_params)

      delivery.update!(
        channel_name: channel.channel_name,
        status: :sent,
        sent_at: Time.current,
        error_message: nil,
        message_id:
      )
    end

    Success(true)
  rescue DiscordClient::ApiError => e
    delivery.with_lock do
      delivery.reload
      return Failure(:already_sent) if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end

    Failure(:api_error)
  end
end
