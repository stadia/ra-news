# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer workspace_id) -> void
  def perform(article_id, workspace_id)
    article = Article.find_by(id: article_id)
    workspace = SlackWorkspace.find_by(id: workspace_id)
    return unless article && workspace&.incoming_webhook_url.present? && workspace.channel_id.present? && workspace.channel_name.present?

    delivery = find_or_create_delivery(article, workspace)
    message = SlackArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      response = SlackClient.new(workspace).post_message(
        text: message.text,
        blocks: message.blocks
      )

      persist_delivery_success(delivery, workspace.channel_name, response["ts"])
    end
  rescue SlackClient::ApiError => e
    delivery&.with_lock do
      delivery.reload
      return if delivery.sent?

      delivery.update!(channel_name: workspace.channel_name, status: :failed, error_message: e.message)
    end
  end

  private

  #: (SlackArticleDelivery delivery, String channel_name, String message_ts) -> void
  def persist_delivery_success(delivery, channel_name, message_ts)
    delivery.update!(
        channel_name:,
        status: :sent,
        sent_at: Time.current,
        error_message: nil,
        slack_message_ts: message_ts
      )
  end

  #: (Article article, SlackWorkspace workspace) -> SlackArticleDelivery
  def find_or_create_delivery(article, workspace)
    existing_delivery = SlackArticleDelivery.find_by(
      article:,
      slack_workspace: workspace,
      channel_id: workspace.channel_id
    )
    return existing_delivery if existing_delivery

    SlackArticleDelivery.create!(
      article:,
      slack_workspace: workspace,
      channel_id: workspace.channel_id,
      channel_name: workspace.channel_name,
      status: :failed
    )
  rescue ActiveRecord::RecordNotUnique
    SlackArticleDelivery.find_by!(
      article:,
      slack_workspace: workspace,
      channel_id: workspace.channel_id
    )
  end
end
