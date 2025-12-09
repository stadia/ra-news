class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    scope = Article.includes(:user, :site).kept.confirmed.related
    article_count = scope.where(created_at: 24.hours.ago...).count
    @articles = if article_count < 9
      scope.limit(9).order(created_at: :desc).sort_by { -it.published_at.to_i }
    else
      scope.where(created_at: 24.hours.ago...).order(created_at: :desc).sort_by { -it.published_at.to_i }
    end
  end

  # GET /rss
  def rss
    @articles = Rails.cache.fetch("rss_articles", expires_in: 1.hour) do
      Article.includes(:user, :site).kept.confirmed.related.order(created_at: :desc).limit(100)
    end
    expires_in 1.hour, public: true
    response.headers["Content-Type"] = "application/rss+xml; charset=utf-8"
    render "rss", formats: [ :rss ], layout: false
  end
end
