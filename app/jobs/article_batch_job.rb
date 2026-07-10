# frozen_string_literal: true
# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  include JobRateLimiting

  queue_as :default

  #: (?Time created_at) -> void
  def perform(created_at = Time.zone.now.beginning_of_day)
    Article.kept.where(title_ko: nil, created_at: created_at...).limit(5).each do |article|
      unless check_rate_limit
        logger.warn("ArticleBatchJob: rate limit reached, stopping batch early")
        break
      end

      begin
        ArticleAgentsService.new.call(article)
      rescue StandardError => e
        logger.error("Error processing article #{article.id}: #{e.message}")
      end
      sleep 1
    end
  end

  private

  def rate_limit_threshold #: Integer
    1
  end

  def rate_limit_window #: ActiveSupport::Duration
    5.minutes
  end
end
