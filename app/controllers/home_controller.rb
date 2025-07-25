class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @articles = Article.kept.where.not(slug: nil).where(created_at: 24.hours.ago...).order(created_at: :desc).sort_by { -it.published_at.to_i }
  end

  # GET /rss
  def rss
    @articles = Article.includes(:user, :site).kept.where.not(slug: nil).order(created_at: :desc).limit(100)
    render "rss", formats: [ :rss ], layout: false
  end
end
