# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/news_media_organization"

class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  # Locale-aware publisher (NewsMediaOrganization) schema — reused in
  # ArticlesController as well. url/logo/masthead 는 현재 호스트 도메인 기준이고
  # same_as 는 양 도메인(.dev/.jp)의 핸들을 모두 포함해 동일 발행 주체임을 표현한다.
  #: (String | Symbol) -> SchemaDotOrg::NewsMediaOrganization
  def self.publisher_schema(locale)
    host = Hosts.for_locale(locale)
    SchemaDotOrg::NewsMediaOrganization.new(
      name:     "Ruby-News",
      url:      host,
      logo:     "#{host}/icon.png",
      same_as:  [
        "https://ruby-news.dev/@bot",
        "https://ruby.social/@news_kr",
        "https://x.com/rubynewskr"
      ],
      masthead: "#{host}/about"
    )
  end

  def index
    cacheable_page!
    scope = article_scope

    @featured_articles = build_featured_articles(scope)
    @articles = build_recent_articles(scope, excluded_ids: @featured_articles.map(&:id))
    @liked_article_ids = liked_article_ids_for(@articles, @featured_articles)
    @boosted_article_ids = boosted_article_ids_for(@articles, @featured_articles)
    @news_media_organization = self.class.publisher_schema(Hosts.locale_for_host(request.host))
    @recent_comments = recent_comments
    @sidebar_tags = sidebar_tags
    render Views::Home::Index.new(
      articles: @articles,
      featured_articles: @featured_articles,
      recent_comments: @recent_comments,
      sidebar_tags: @sidebar_tags,
      liked_article_ids: @liked_article_ids,
      boosted_article_ids: @boosted_article_ids
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

  # GET /llms.txt — 요청 호스트별 llms.txt 동적 서빙.
  # public 캐시(max-age=1day)이므로 쿠키·사용자 로케일이 아니라 request.host 로
  # 본문을 결정해야 캐시 오염(다른 방문자에게 잘못된 언어 제공)을 방지한다.
  def llms
    cacheable_page!(max_age: 1.day)
    body = LLMS_TXT.fetch(Hosts.locale_for_host(request.host))
    render plain: body, content_type: "text/plain"
  end

  private

  # llms.txt 본문은 정적 텍스트 파일에서 로드한다 (app/views/home/llms/{ko,ja}.txt).
  LLMS_TXT = {
    ko: Rails.root.join("app/views/home/llms/ko.txt").read.freeze,
    ja: Rails.root.join("app/views/home/llms/ja.txt").read.freeze
  }.freeze

  def article_scope
    Article.includes(:user, :site).with_attached_thumbnail.kept.confirmed.related
  end

  def build_featured_articles(scope)
    featured_scope = scope.without_toast.where(created_at: 48.hours.ago...)
    featured_articles = primary_featured_articles(featured_scope)

    if featured_articles.size < 3
      featured_articles.concat(fallback_featured_articles(featured_scope, featured_articles))
    end

    featured_articles.sort_by { [ -it.likers_count, -it.boosters_count, -it.posts_count, -it.published_at.to_i, -it.created_at.to_i ] }
  end

  def primary_featured_articles(featured_scope)
    featured_scope
      .where("likers_count > ? OR posts_count > ? OR boosters_count > ?", 0, 0, 0)
      .order(likers_count: :desc, posts_count: :desc, boosters_count: :desc, created_at: :desc)
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

  def boosted_article_ids_for(articles, featured_articles)
    Boost.boosted_ids_for(
      booster: current_user,
      boostable_type: "Article",
      boostable_ids: (articles + featured_articles).map(&:id)
    )
  end

  def recent_comments
    Post.comments.kept
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
