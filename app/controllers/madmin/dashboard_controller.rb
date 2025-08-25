module Madmin
  class DashboardController < Madmin::ApplicationController
    def show
      @articles_count = Article.kept.count
      @sites_count = Site.count
      @users_count = User.count
      @comments_count = Comment.count

      @recent_articles = Article.kept.includes(:site).order(created_at: :desc).limit(5)
      @recent_comments = Comment.includes(:article, :user).order(created_at: :desc).limit(5)

      @popular_tags = ActsAsTaggableOn::Tag.most_used(10)

      # 이번 주 새 기사 수
      @weekly_articles = Article.kept.where(created_at: 1.week.ago..Time.current).count

      # 활성 RSS 사이트 수 (최근 1주일 내 기사가 있는 사이트)
      @active_sites = Site.joins(:articles).where(articles: { created_at: 1.week.ago..Time.current }).distinct.count
    end
  end
end
