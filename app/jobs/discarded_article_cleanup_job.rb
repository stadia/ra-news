# frozen_string_literal: true
# rbs_inline: enabled

class DiscardedArticleCleanupJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500
  RETENTION_PERIOD = 6.months

  #: () -> void
  def perform
    cutoff = RETENTION_PERIOD.ago
    scope = Article.discarded.where(created_at: ...cutoff)

    scope.in_batches(of: BATCH_SIZE) do |batch|
      article_ids = batch.pluck(:id)
      next if article_ids.empty?

      Post.where(article_id: article_ids).update_all(article_id: nil)
      NotificationDelivery.where(article_id: article_ids).delete_all
      Article.where(id: article_ids).delete_all
    end
  end
end
