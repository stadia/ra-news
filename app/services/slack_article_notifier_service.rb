# frozen_string_literal: true

class SlackArticleNotifierService
  def call(article)
    return unless article.deleted_at.nil? && article.slug.present? && article.title_ko.present?

    message = SlackMessageBuilder.new(article)

    targets.each do |target|
      delivery = SlackArticleDelivery.find_or_initialize_by(
        article:,
        slack_workspace: target[:workspace],
        channel_id: target[:channel_id]
      )
      next if delivery.persisted? && delivery.sent?

      begin
        response = SlackClient.new(target[:workspace]).post_message(
          channel: target[:channel_id],
          text: message.text,
          blocks: message.blocks
        )

        delivery.assign_attributes(
          channel_name: target[:channel_name],
          status: :sent,
          sent_at: Time.current,
          error_message: nil,
          slack_message_ts: response["ts"]
        )
      rescue SlackClient::ApiError => e
        delivery.assign_attributes(
          channel_name: target[:channel_name],
          status: :failed,
          error_message: e.message
        )
      end

      delivery.save!
    end
  end

  private

  def targets
    UserWorkspaceSubscription.active
      .includes(:slack_workspace)
      .select { |subscription| subscription.slack_workspace&.active? }
      .uniq { |subscription| [ subscription.slack_workspace_id, subscription.channel_id ] }
      .map do |subscription|
        {
          workspace: subscription.slack_workspace,
          channel_id: subscription.channel_id,
          channel_name: subscription.channel_name
        }
      end
  end
end
