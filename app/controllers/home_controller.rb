# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/news_media_organization"

class HomeController < ApplicationController
  skip_before_action :authenticate_user!

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
    scope = Article.includes(:user, :site).with_attached_thumbnail.kept.confirmed.related
    @featured_articles = scope.without_toast
      .where("likers_count > 0 OR EXISTS (SELECT 1 FROM posts WHERE posts.article_id = articles.id)")
      .order(published_at: :desc)
      .limit(3)
      .to_a
    featured_ids = @featured_articles.map(&:id)
    remaining_scope = scope.where.not(id: featured_ids)
    article_count = remaining_scope.where(created_at: 24.hours.ago...).count
    @articles = if article_count < 9
      remaining_scope.without_toast.limit(9).order(created_at: :desc).sort_by { -it.published_at.to_i }
    else
      remaining_scope.without_toast.where(created_at: 24.hours.ago...).order(created_at: :desc).sort_by { -it.published_at.to_i }
    end
    @liked_article_ids = Like.liked_ids_for(
      liker: current_user,
      likeable_type: "Article",
      likeable_ids: (@articles + @featured_articles).map(&:id)
    )

    @news_media_organization = PUBLISHER_SCHEMA
    @recent_comments = Post.comments
      .joins(:article)
      .preload(:article, :federails_actor, user: { avatar_attachment: :blob })
      .where(article: { deleted_at: nil })
      .order(created_at: :desc)
      .limit(10)
    @sidebar_tags = Tag.confirmed.order(taggings_count: :desc, name: :asc).limit(20)
    render Views::Home::Index.new(
      articles: @articles,
      featured_articles: @featured_articles,
      recent_comments: @recent_comments,
      sidebar_tags: @sidebar_tags,
      liked_article_ids: @liked_article_ids
    )
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
      Article.includes(:user, :site, :thumbnail_attachment).kept.confirmed.related.without_toast.order(created_at: :desc).limit(100)
    end
    response.headers["Content-Type"] = "application/rss+xml; charset=utf-8"
    render "rss", formats: [ :rss ], layout: false
  end
end
