# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class SlackDeliveryService < OperationService
  #: (Article article, SlackChannel channel) -> Dry::Monads::Result
  def call(article, channel)
    delivery = step find_or_create_delivery(article, channel)
    step send_message(article, channel, delivery:)
  end

  private

  #: (Article article, SlackChannel channel) -> Dry::Monads::Result
  def find_or_create_delivery(article, channel)
    existing = SlackDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return Success(existing) if existing

    delivery = SlackDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
    Success(delivery)
  rescue ActiveRecord::RecordNotUnique
    delivery = SlackDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    Success(delivery)
  end

  #: (Article article, SlackChannel channel, delivery: SlackDelivery) -> Dry::Monads::Result
  def send_message(article, channel, delivery:)
    message = SlackArticlePresenter.new(article)

    delivery.with_lock do
      return Failure(:already_sent) if delivery.sent?

      response = SlackClient.new(channel).post_message(
        text: message.text,
        blocks: message.blocks
      )

      delivery.update!(
        channel_name: channel.channel_name,
        status: :sent,
        sent_at: Time.current,
        error_message: nil,
        message_id: response["ts"]
      )
    end

    Success(true)
  rescue SlackClient::ApiError => e
    delivery.with_lock do
      delivery.reload
      return Failure(:already_sent) if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end

    Failure(:api_error)
  end
end
