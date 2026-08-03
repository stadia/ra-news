# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class ArticleBatchJob < ApplicationJob
  include JobRateLimiting

  queue_as :default

  # `Time.zone.now` returns an ActiveSupport::TimeWithZone, which only quacks
  # like Time -- it is not a subclass -- so the default value does not satisfy
  # a bare `Time` annotation.
  #: (?(Time | ActiveSupport::TimeWithZone) created_at) -> void
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

  #: () -> Integer
  def rate_limit_threshold
    1
  end

  #: () -> ActiveSupport::Duration
  def rate_limit_window
    5.minutes
  end
end
