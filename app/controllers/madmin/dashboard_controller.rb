# frozen_string_literal: true

module Madmin
  class DashboardController < Madmin::ApplicationController
    def show
      # ── 핵심 지표 ──
      @articles_count = Article.kept.count
      @sites_count = Site.count
      @users_count = User.count
      @comments_count = Post.comments.count
      @likes_count = Like.count

      # ── 주간 추세 ──
      @weekly_articles = Article.kept.where(created_at: 1.week.ago..Time.current).count
      @prev_weekly_articles = Article.kept.where(created_at: 2.weeks.ago..1.week.ago).count
      @weekly_comments = Post.comments.where(created_at: 1.week.ago..Time.current).count
      @prev_weekly_comments = Post.comments.where(created_at: 2.weeks.ago..1.week.ago).count
      @weekly_users = User.where(created_at: 1.week.ago..Time.current).count

      # ── 일별 기사 수 (최근 14일) ──
      @daily_articles = (13.days.ago.to_date..Date.current).map do |day|
        [day, Article.kept.where("DATE(created_at) = ?", day).count]
      end.to_h

      # ── 최근 활동 ──
      @recent_articles = Article.kept.includes(:site).order(created_at: :desc).limit(8)
      @recent_comments = Post.comments.includes(:article, :user).order(created_at: :desc).limit(6)

      # ── 태그 ──
      @popular_tags = ActsAsTaggableOn::Tag.most_used(15)

      # ── 콘텐츠 분해 ──
      @articles_by_client = Site.group(:client).count.transform_keys { |k| k.to_sym }
      @youtube_count = Article.kept.where(is_youtube: true).count
      @related_count = Article.kept.where(is_related: true).count
      @posted_count = Article.kept.where(is_posted: true).count
      @summarized_count = Article.kept.where.not(summary_key: nil).count

      # ── 알림 배송 건강 ──
      @notification_sent = NotificationDelivery.where(status: "sent").count
      @notification_failed = NotificationDelivery.where(status: "failed").count
      @notification_total = @notification_sent + @notification_failed

      # ── 활성 RSS 사이트 ──
      @active_sites = Site.joins(:articles).where(articles: { created_at: 1.week.ago..Time.current }).distinct.count

      # ── 사용자 통계 ──
      @confirmed_users = User.where.not(confirmed_at: nil).count

      # ── 호스트 순위 (6~15위, 장기미 목록) ──
      @top_hosts = Article.kept.group(:host)
                             .order("count_all DESC")
                             .limit(15)
                             .offset(5)
                             .count
    end
  end
end