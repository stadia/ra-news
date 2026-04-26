# frozen_string_literal: true
# rbs_inline: enabled

module SlackNotifier
  module_function

  #: (Article article) -> bool?
  def notify(article)
    return if article.deleted_at.present?
    return unless article.slug.present? && article.title_ko.present?

    delivery_jobs = SlackChannel.delivery_ready.order(:id).map do |channel|
      SlackArticleDeliveryJob.new(article.id, channel.id)
    end

    return if delivery_jobs.empty?

    ActiveJob.perform_all_later(delivery_jobs)
    true
  end
end
