require "schema_dot_org/news_media_organization"

class HomeController < ApplicationController
  allow_unauthenticated_access

  # Shared publisher schema — reused in ArticlesController as well
  PUBLISHER_SCHEMA = SchemaDotOrg::NewsMediaOrganization.new(
    name:     "Ruby-News",
    url:      "https://ruby-news.kr",
    logo:     "https://ruby-news.kr/icon.png",
    same_as:  [ "https://ruby-news.kr/@bot", "https://ruby.social/@news_kr", "https://x.com/rubynewskr" ],
    masthead: "https://ruby-news.kr/about"
  )

  def index
    cacheable_page!
    scope = Article.includes(:user, :site).kept.confirmed.related
    article_count = scope.where(created_at: 24.hours.ago...).count
    @articles = if article_count < 9
      scope.without_toast.limit(9).order(created_at: :desc).sort_by { -it.published_at.to_i }
    else
      scope.without_toast.where(created_at: 24.hours.ago...).order(created_at: :desc).sort_by { -it.published_at.to_i }
    end

    @news_media_organization = PUBLISHER_SCHEMA
    @recent_comments = Comment.joins(:article).includes(:article, :user).where(article: { deleted_at: nil }).order(created_at: :desc).limit(10)
    render Views::Home::Index.new(articles: @articles, recent_comments: @recent_comments)
  end

  # GET /about
  def about
    cacheable_page!
    render Views::Home::About.new
  end

  # GET /rss
  def rss
    cacheable_page!(max_age: 1.hour)
    @articles = Rails.cache.fetch("rss_articles", expires_in: 1.hour) do
      Article.includes(:user, :site).kept.confirmed.related.without_toast.order(created_at: :desc).limit(100)
    end
    response.headers["Content-Type"] = "application/rss+xml; charset=utf-8"
    render "rss", formats: [ :rss ], layout: false
  end
end
