module Madmin
  class DashboardController < ApplicationController
    # rbs_inline: enabled

    def show #: () -> void
      @article_stats = {
        total: Article.kept.count,
        recent: Article.kept.order(created_at: :desc).limit(5),
        discarded: Article.discarded.count,
        today: Article.kept.where(created_at: Date.current.all_day).count
      }

      @site_stats = {
        total: Site.count,
        active: Site.where.not(last_checked_at: nil).count,
        recent_feeds: Site.order(last_checked_at: :desc).limit(5)
      }

      @user_stats = {
        total: User.count,
        recent: User.order(created_at: :desc).limit(5)
      }

      @comment_stats = {
        total: Comment.count,
        recent: Comment.order(created_at: :desc).limit(5)
      }

      @system_stats = {
        database_size: get_database_size,
        cache_keys: Rails.cache.respond_to?(:stats) ? Rails.cache.stats : nil
      }
    end

    private

    def get_database_size #: () -> String
      result = ActiveRecord::Base.connection.execute(
        "SELECT pg_size_pretty(pg_database_size(current_database())) as size"
      )
      result.first["size"]
    rescue StandardError
      "Unknown"
    end
  end
end