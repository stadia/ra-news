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
    deleted_any = false
    nulled_posts_count = 0
    deleted_notifications_count = 0
    deleted_articles_count = 0

    logger.info("DiscardedArticleCleanupJob started: cutoff=#{cutoff.iso8601}, batch_size=#{BATCH_SIZE}, target_count=#{scope.count}")

    scope.in_batches(of: BATCH_SIZE) do |batch|
      article_ids = batch.pluck(:id)
      next if article_ids.empty?

      nulled_posts = Post.where(article_id: article_ids).update_all(article_id: nil)
      deleted_notifications = NotificationDelivery.where(article_id: article_ids).delete_all
      deleted_articles = Article.where(id: article_ids).delete_all

      nulled_posts_count += nulled_posts
      deleted_notifications_count += deleted_notifications
      deleted_articles_count += deleted_articles
      deleted_any ||= deleted_articles.positive?

      logger.info(
        "DiscardedArticleCleanupJob batch completed: article_ids=#{article_ids.size}, nulled_posts=#{nulled_posts}, deleted_notifications=#{deleted_notifications}, deleted_articles=#{deleted_articles}"
      )
    end

    vacuum_articles if deleted_any

    logger.info(
      "DiscardedArticleCleanupJob finished: deleted_articles=#{deleted_articles_count}, deleted_notifications=#{deleted_notifications_count}, nulled_posts=#{nulled_posts_count}, vacuum_run=#{deleted_any}"
    )
  end

  private

  #: () -> void
  def vacuum_articles
    Article.connection_pool.with_connection do |connection|
      if connection.transaction_open?
        logger.warn("DiscardedArticleCleanupJob skipped vacuum: open transaction")
        return
      end

      connection.execute("VACUUM ANALYZE #{Article.quoted_table_name}")
      logger.info("DiscardedArticleCleanupJob vacuum completed for #{Article.table_name}")
    end
  end
end
