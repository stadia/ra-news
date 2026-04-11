# frozen_string_literal: true

class SlackArticleDeliveryJob < ApplicationJob
  queue_as :default

  def perform(article_id, workspace_id, channel_id, channel_name)
    article = Article.find_by(id: article_id)
    workspace = SlackWorkspace.find_by(id: workspace_id)
    return unless article && workspace

    delivery = find_or_create_delivery(article, workspace, channel_id, channel_name)
    message = SlackArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      response = SlackClient.new(workspace).post_message(
        channel: channel_id,
        text: message.text,
        blocks: message.blocks
      )

      return if persist_delivery_success(delivery, channel_name, response["ts"])

      Rails.logger.error(
        "SlackArticleDeliveryJob failed to persist sent delivery " \
        "delivery_id=#{delivery.id} article_id=#{article.id} workspace_id=#{workspace.id} " \
        "channel_id=#{channel_id} errors=#{delivery.errors.full_messages.join(', ')}"
      )
      raise ActiveRecord::RecordInvalid, delivery
    end
  rescue SlackClient::ApiError => e
    delivery&.update!(channel_name:, status: :failed, error_message: e.message)
  end

  private

  def persist_delivery_success(delivery, channel_name, message_ts)
    delivery.update(
        channel_name:,
        status: :sent,
        sent_at: Time.current,
        error_message: nil,
        slack_message_ts: message_ts
      )
  end

  def find_or_create_delivery(article, workspace, channel_id, channel_name)
    SlackArticleDelivery.create!(
      article:,
      slack_workspace: workspace,
      channel_id:,
      channel_name:,
      status: :failed
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    SlackArticleDelivery.find_by!(
      article:,
      slack_workspace: workspace,
      channel_id:
    )
  end
end
