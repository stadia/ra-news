# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Madmin
  class DashboardController < Madmin::ApplicationController
    def show
      assign_core_metrics
      assign_weekly_trends
      assign_daily_articles
      assign_recent_activity
      assign_tags
      assign_content_breakdown
      assign_notification_health
      assign_site_and_user_stats
      assign_top_hosts
    end

    private

    def assign_core_metrics
      @articles_count = Article.kept.count
      @sites_count = Site.count
      @users_count = User.count
      @comments_count = Post.comments.count
      @likes_count = Like.count
    end

    def assign_weekly_trends
      @weekly_articles = Article.kept.where(created_at: current_week_range).count
      @prev_weekly_articles = Article.kept.where(created_at: previous_week_range).count
      @weekly_comments = Post.comments.where(created_at: current_week_range).count
      @prev_weekly_comments = Post.comments.where(created_at: previous_week_range).count
      @weekly_users = User.where(created_at: current_week_range).count
    end

    def assign_daily_articles
      @daily_articles = (13.days.ago.to_date..Date.current).map do |day|
        [ day, Article.kept.where("DATE(created_at) = ?", day).count ]
      end.to_h
    end

    def assign_recent_activity
      @recent_articles = Article.kept.includes(:site).order(created_at: :desc).limit(8)
      @recent_comments = Post.comments.includes(:article, :user).order(created_at: :desc).limit(6)
    end

    def assign_tags
      @popular_tags = ActsAsTaggableOn::Tag.most_used(15)
    end

    def assign_content_breakdown
      @articles_by_client = Site.group(:client).count.transform_keys { |key| key.to_sym }
      @youtube_count = Article.kept.where(is_youtube: true).count
      @related_count = Article.kept.where(is_related: true).count
      @posted_count = Article.kept.where(is_posted: true).count
      @summarized_count = Article.kept.where.not(summary_key: nil).count
    end

    def assign_notification_health
      @notification_sent = NotificationDelivery.where(status: "sent").count
      @notification_failed = NotificationDelivery.where(status: "failed").count
      @notification_total = @notification_sent + @notification_failed
    end

    def assign_site_and_user_stats
      @active_sites = Site.joins(:articles).where(articles: { created_at: current_week_range }).distinct.count
      @confirmed_users = User.where.not(confirmed_at: nil).count
    end

    def assign_top_hosts
      registered_hosts = Site.where.not(base_uri: [ nil, "" ]).pluck(:base_uri)
                                 .filter_map { |uri| URI.parse(uri).host }
      registered_hosts += [ "www.youtube.com", "github.com", "thoughtbot.com" ]
      @top_hosts = Article.kept.where.not(host: registered_hosts)
                           .group(:host)
                           .order("count_all DESC")
                           .limit(30)
                           .count
    end

    def current_week_range
      1.week.ago..Time.current
    end

    def previous_week_range
      2.weeks.ago..1.week.ago
    end
  end
end
