# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/news_media_organization"

class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  # Shared publisher schema — reused in ArticlesController as well
  PUBLISHER_SCHEMA = SchemaDotOrg::NewsMediaOrganization.new(
    name:     "Ruby-News",
    url:      "https://ruby-news.dev",
    logo:     "https://ruby-news.dev/icon.png",
    same_as:  [ "https://ruby-news.dev/@bot", "https://ruby.social/@news_kr", "https://x.com/rubynewskr" ],
    masthead: "https://ruby-news.dev/about"
  )

  def index
    cacheable_page!
    scope = article_scope

    @featured_articles = build_featured_articles(scope)
    @articles = build_recent_articles(scope, excluded_ids: @featured_articles.map(&:id))
    @liked_article_ids = liked_article_ids_for(@articles, @featured_articles)
    @news_media_organization = PUBLISHER_SCHEMA
    @recent_comments = recent_comments
    @sidebar_tags = sidebar_tags
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

  # GET /privacy-policy
  def privacy_policy
    cacheable_page!
    render Views::Home::PrivacyPolicy.new
  end

  # GET /terms
  def terms
    cacheable_page!
    render Views::Home::Terms.new
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

  private

  def article_scope
    Article.includes(:user, :site).with_attached_thumbnail.kept.confirmed.related
  end

  def build_featured_articles(scope)
    featured_scope = scope.without_toast.where(created_at: 48.hours.ago...)
    featured_articles = primary_featured_articles(featured_scope)

    if featured_articles.size < 3
      featured_articles.concat(fallback_featured_articles(featured_scope, featured_articles))
    end

    featured_articles.sort_by { [ -it.likers_count, -it.posts_count, -it.published_at.to_i, -it.created_at.to_i ] }
  end

  def primary_featured_articles(featured_scope)
    featured_scope
      .where("likers_count > ? OR posts_count > ?", 0, 0)
      .order(likers_count: :desc, posts_count: :desc, created_at: :desc)
      .limit(3)
      .to_a
  end

  def fallback_featured_articles(featured_scope, featured_articles)
    featured_scope
      .where.not(id: featured_articles.map(&:id))
      .order(published_at: :desc, created_at: :desc)
      .limit(3 - featured_articles.size)
      .to_a
  end

  def build_recent_articles(scope, excluded_ids:)
    remaining_scope = scope.where.not(id: excluded_ids)
    articles = if remaining_scope.where(created_at: 24.hours.ago...).count < 9
      remaining_scope.without_toast.order(created_at: :desc).limit(9)
    else
      remaining_scope.without_toast.where(created_at: 24.hours.ago...).order(created_at: :desc)
    end

    articles.sort_by { -it.published_at.to_i }
  end

  def liked_article_ids_for(articles, featured_articles)
    Like.liked_ids_for(
      liker: current_user,
      likeable_type: "Article",
      likeable_ids: (articles + featured_articles).map(&:id)
    )
  end

  def recent_comments
    Post.comments
      .joins(:article)
      .preload(:article, :federails_actor, user: { avatar_attachment: :blob })
      .where(article: { deleted_at: nil })
      .order(created_at: :desc)
      .limit(10)
  end

  def sidebar_tags
    Tag.confirmed.order(taggings_count: :desc, name: :asc).limit(20)
  end
end
