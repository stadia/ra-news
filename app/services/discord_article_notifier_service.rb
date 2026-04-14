# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticleNotifierService < OperationService
  #: (Article article) -> Dry::Monads::Result
  def call(article)
    return Failure(:deleted) unless article.deleted_at.nil?
    return Failure(:not_confirmed) unless article.slug.present? && article.title_ko.present?

    delivery_jobs = DiscordChannel.delivery_ready.order(:id).to_a.map do |channel|
      DiscordArticleDeliveryJob.new(article.id, channel.id)
    end

    return nil if delivery_jobs.empty?

    ActiveJob.perform_all_later(delivery_jobs)

    true
  end
end
