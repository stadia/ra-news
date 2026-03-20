# frozen_string_literal: true

# rbs_inline: enabled

require "schema_dot_org/news_article"
require "schema_dot_org/breadcrumb_list"

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show others ]

  before_action :set_article, only: %i[ show ]

  include Pagy::Method

  # GET /articles or /articles.json
  def index
    cacheable_page!
    scope = Article.kept.confirmed

    article = if params[:search].present?
      scope.full_text_search_for(params[:search])
    else
      scope = scope.related
      article_count = scope.where(created_at: 24.hours.ago...).order(created_at: :desc).count
      id = if article_count < 9
        scope.select(:id).limit(9).order(created_at: :desc).map(&:id)
      else
        scope.select(:id).where(created_at: 24.hours.ago...).order(created_at: :desc).map(&:id)
      end
      scope.where.not(id: id)
    end
    @pagy, @articles = pagy(article.includes(:user, :site).order(published_at: :desc))
    render Views::Articles::Index.new(pagy: @pagy, articles: @articles, search: params[:search])
  end

  def others
    cacheable_page!
    article = Article.kept.confirmed.unrelated
    @pagy, @articles = pagy(article.includes(:user, :site).order(published_at: :desc))
    render Views::Articles::Others.new(pagy: @pagy, articles: @articles, search: params[:search])
  end

  def show
    @comments = @article.comments.includes(:user)

    @page_title = @article.title_ko
    @page_description = @article.summary_key&.first
    @page_keywords = @article.tags.map(&:name).join(",") unless @article.tags.empty?
    @og_type = "article"
    @og_article = {
      published_time: @article.published_at&.iso8601,
      modified_time:  @article.updated_at.iso8601,
      tag:            @article.tags.map(&:name).presence
    }.compact
    if @article.title.present? || @article.title_ko.present?
      @news_article = SchemaDotOrg::NewsArticle.new(
        headline:       @article.title_ko.presence || @article.title,
        description:    @article.summary_key&.first,
        url:            article_url(@article),
        date_published: @article.published_at&.iso8601,
        date_modified:  @article.updated_at.iso8601,
        in_language:    "ko-KR",
        is_based_on:    @article.url,
        publisher: HomeController::PUBLISHER_SCHEMA
      )
    end
    @breadcrumbs = SchemaDotOrg.make_breadcrumbs([
      { name: "홈",  url: root_url },
      { name: "기사", url: articles_url },
      { name: @article.title_ko }
    ])

    # Only load similar articles if embedding exists
    @similar_articles = if @article.embedding.present?
      Article.kept.confirmed.where.not(id: @article.id)
             .nearest_neighbors(:embedding, @article.embedding, distance: "euclidean")
             .limit(4)
    else
      Article.none
    end

    @comment = Comment.new
    render Views::Articles::Show.new(
      article: @article,
      comments: @comments,
      comment: @comment,
      similar_articles: @similar_articles
    )
  end

  # GET /articles/new
  def new
    @article = Article.new(user: Current.user)
    render Views::Articles::New.new(article: @article)
  end

  # POST /articles
  def create
    url = article_params[:url]&.strip
    @article = Article.new(url:, origin_url: url, user: User.first_bot)

    respond_to do |format|
      if @article.save
        ArticleJob.perform_later(@article.id)
        format.html { redirect_to article_path(@article), notice: "Article was successfully created." }
      else
        if @article.errors.details[:origin_url].any? { |e| e[:error] == :taken } && @article.errors.details[:url].any? { |e| e[:error] == :taken }
          format.html { redirect_to article_path(existing_article), notice: "Article already exists." }
        else
          format.html { render Views::Articles::New.new(article: @article), status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.error e
      format.html { redirect_to article_path(existing_article), notice: "Article already exists." }
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
end
