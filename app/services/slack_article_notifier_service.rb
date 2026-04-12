# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleNotifierService < OperationService
  #: (Article article) -> Dry::Monads::Result
  def call(article)
    return Failure(:deleted) unless article.deleted_at.nil?
    return Failure(:not_confirmed) unless article.slug.present? && article.title_ko.present?

    delivery_jobs = SlackWorkspace.delivery_ready.order(:id).to_a.map do |workspace|
      SlackArticleDeliveryJob.new(article.id, workspace.id)
    end

    return nil if delivery_jobs.empty?

    ActiveJob.perform_all_later(delivery_jobs)

    true
  end
end
