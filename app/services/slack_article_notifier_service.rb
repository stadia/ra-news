# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleNotifierService < OperationService
  def call(article)
    return Failure(:deleted) unless article.deleted_at.nil?
    return Failure(:not_confirmed) unless article.slug.present? && article.title_ko.present?

    delivery_jobs = targets.each do |target|
      SlackArticleDeliveryJob.new(
        article.id,
        target[:workspace].id,
        target[:channel_id],
        target[:channel_name]
      )
    end
    ActiveJob.perform_all_later(delivery_jobs)

    Success(true)
  end

  private

  def targets
    WorkspaceSubscription.active
      .joins(:slack_workspace)
      .merge(SlackWorkspace.active)
      .includes(:slack_workspace)
      .group_by { |sub| [ sub.slack_workspace_id, sub.channel_id ] }
      .values
      .map(&:first)
      .map do |subscription|
        {
          workspace: subscription.slack_workspace,
          channel_id: subscription.channel_id,
          channel_name: subscription.channel_name
        }
      end
  end
end
