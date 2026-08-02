# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class SocialPostJob < ApplicationJob
  include JobRateLimiting

  queue_as :default

  #: (?Integer? id, ?Time created_at) -> void
  def perform(id = nil, created_at = Time.zone.now.beginning_of_day)
    return unless Rails.env.production?

    scope = Article.kept
    scope = if id.nil?
      scope.confirmed.where("is_posted = ?", false).where(created_at: created_at..).limit(4)
    else
      scope.where("id = ? AND is_posted = ?", id, false)
    end

    scope.find_each do |article|
      unless check_rate_limit
        logger.warn("SocialPostJob: rate limit reached, stopping batch early")
        break
      end

      # TwitterService.new.call(article)
      MastodonService.new.call(article)
      SlackNotifier.notify(article)
      DiscordNotifier.notify(article)
      article.update(is_posted: true)
      sleep 2
    end
  end

  #: () -> Integer
  def rate_limit_threshold
    2
  end

  #: () -> ActiveSupport::Duration
  def rate_limit_window
    5.minutes
  end
end
