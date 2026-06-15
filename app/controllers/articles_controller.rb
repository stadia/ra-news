# frozen_string_literal: true
# rbs_inline: enabled

require "schema_dot_org/news_article"
require "schema_dot_org/breadcrumb_list"
require "schema_dot_org/creative_work"

class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[ index show others tag ]

  before_action :set_article, only: %i[ show ]

  include Pagy::Method

  SEARCH_TERM_MAX_LENGTH = 100

  # GET /articles
  def index
    cacheable_page!

    search = normalized_search_term
    source = search.present? && params[:source] == "google" ? :google : :ruby_news
    if source == :google
      render Views::Articles::Index.new(search:, source:)
      return
    end

    @pagy, @articles = pagy(Articles::Query.index_html(search))
    suggestions = @articles.empty? && search.present? ? Articles::Search.suggest(search) : []
    render Views::Articles::Index.new(
      pagy: @pagy,
      articles: @articles,
      sidebar_tags: sidebar_tags,
      search: search,
      source: source,
      liked_article_ids: liked_article_ids(@articles),
      boosted_article_ids: boosted_article_ids(@articles),
      suggestions: suggestions
    )
  end

  def others
    cacheable_page!

    @pagy, @articles = pagy(Articles::Query.others.order(published_at: :desc))
    render Views::Articles::Others.new(
      pagy: @pagy,
      articles: @articles,
      sidebar_tags: sidebar_tags,
      search: params[:search],
      liked_article_ids: liked_article_ids(@articles),
      boosted_article_ids: boosted_article_ids(@articles)
    )
  end

  def tag
    cacheable_page!
    keyword = params[:keyword].to_s

    @pagy, @articles = pagy(Articles::Query.tagged(keyword).order(published_at: :desc))
    render Views::Articles::Tagged.new(
      pagy: @pagy,
      articles: @articles,
      tag: keyword,
      sidebar_tags: sidebar_tags,
      liked_article_ids: liked_article_ids(@articles),
      boosted_article_ids: boosted_article_ids(@articles)
    )
  end

  def show
    @comments = @article.posts.comments.kept.includes(:user)

    @page_title = @article.display_title
    @page_description = @article.summary_key_preview
    @page_keywords = @article.tags.map(&:name).join(",") unless @article.tags.empty?
    @og_type = "article"
    @og_image = rails_blob_url(@article.thumbnail, disposition: "inline") if @article.thumbnail.attached?
    @og_article = {
      published_time: @article.published_at&.iso8601,
      modified_time:  @article.updated_at.iso8601,
      tag:            @article.tags.map(&:name).presence
    }.compact
    if @article.display_title.present?
      # publisher(발행 주체 = 어느 사이트냐)는 쿠키·사용자 로케일이 아니라
      # 실제 요청 호스트로 결정한다. in_language 는 실제 렌더 콘텐츠 언어이므로
      # I18n.locale 기준을 유지한다.
      publisher = HomeController.publisher_schema(Hosts.locale_for_host(request.host))
      news_article_attrs = {
        headline:            @article.display_title,
        description:         @article.summary_key_preview,
        url:                 article_url(@article),
        date_published:      @article.published_at&.iso8601,
        date_modified:       @article.updated_at.iso8601,
        in_language:         I18n.locale == :ja ? "ja-JP" : "ko-KR",
        is_based_on:         @article.url,
        translation_of_work: SchemaDotOrg::CreativeWork.new(url: @article.url),
        speakable:           article_speakable,
        author:              publisher,
        publisher:           publisher
      }
      news_article_attrs[:image] = @og_image if @og_image
      @news_article = SchemaDotOrg::NewsArticle.new(**news_article_attrs)
    end
    @breadcrumbs = SchemaDotOrg.make_breadcrumbs([
      { name: t("layout.nav.home"),  url: root_url },
      { name: t("articles.index.heading"), url: articles_url },
      { name: @article.display_title }
    ])

    # Only load similar articles if embedding exists
    @similar_articles = if @article.embedding.present?
      Article.kept.confirmed.where.not(id: @article.id)
             .nearest_neighbors(:embedding, @article.embedding, distance: "cosine")
             .limit(4)
    else
      Article.none
    end

    @comment = Post.new
    respond_to do |format|
      format.html do
        render Views::Articles::Show.new(
          article: @article,
          comments: @comments,
          comment: @comment,
          similar_articles: @similar_articles
        )
      end
      format.md { render markdown: @article }
    end
  end

  # GET /articles/new
  def new
    @article = Article.new(user: current_user)
    render Views::Articles::New.new(article: @article)
  end

  # POST /articles
  def create
    url = article_params[:url]&.strip
    @article = Article.new(url:, origin_url: url, user: User.first_bot)

    respond_to do |format|
      if @article.save
        ArticleJob.perform_later(@article.id)
        format.html { redirect_to article_path(@article), notice: t("articles.create.success") }
      else
        if @article.errors.details[:origin_url].any? { |e| e[:error] == :taken } && @article.errors.details[:url].any? { |e| e[:error] == :taken }
          format.html { redirect_to article_path(existing_article), notice: t("articles.create.already_exists") }
        else
          format.html { render Views::Articles::New.new(article: @article), status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.error e
      format.html { redirect_to article_path(existing_article), notice: t("articles.create.already_exists") }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      id = params[:id]
      return head :bad_request if id.blank?

      @article = Article.kept.friendly.find(id)
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.require(:article).permit(:url)
    rescue ActionController::ParameterMissing
      # Return empty parameters if article params are missing
      ActionController::Parameters.new({}).permit!
    end

    def existing_article
      Article.where(url: @article.url).or(Article.where(origin_url: @article.origin_url)).first
    end

    def liked_article_ids(articles)
      Like.liked_ids_for(
        liker: current_user,
        likeable_type: "Article",
        likeable_ids: articles.map(&:id)
      )
    end

    def boosted_article_ids(articles)
      Boost.boosted_ids_for(
        booster: current_user,
        boostable_type: "Article",
        boostable_ids: articles.map(&:id)
      )
    end

    def sidebar_tags
      @sidebar_tags ||= Tag.confirmed.order(taggings_count: :desc, name: :asc).limit(20)
    end

    def normalized_search_term
      params[:search].to_s.strip.first(SEARCH_TERM_MAX_LENGTH).presence
    end

    # 음성 비서(Google Assistant 등)가 읽어줄 핵심 영역을 가리키는
    # SpeakableSpecification. 기사 헤드라인(h1)과 본문 요약 블록
    # (#article-detail-body, app/views/articles/show.rb) 을 대상으로 한다.
    def article_speakable
      SchemaDotOrg::SpeakableSpecification.new(
        css_selector: [ "h1", "#article-detail-body" ]
      )
    end
end
