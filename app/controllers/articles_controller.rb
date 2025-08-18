# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_article, only: %i[ show edit ]

  include Pagy::Backend

  # GET /articles or /articles.json
  def index
    scope = Article.kept.where.not(slug: nil)

    # 태그 필터링
    if params[:tag].present?
      scope = scope.tagged_with(params[:tag])
      @current_tag = params[:tag]
    end

    # 최신 기사 제외 로직 (검색이나 태그 필터가 없을 때만)
    id = if params[:search].blank? && params[:tag].blank?
      article_count = scope.where(created_at: 24.hours.ago...).order(created_at: :desc).count
      if article_count < 8
        scope.select(:id).limit(8).order(created_at: :desc).map(&:id)
      else
        scope.select(:id).where(created_at: 24.hours.ago...).order(created_at: :desc).map(&:id)
      end
    else
      []
    end

    article = if params[:search].present?
      scope.full_text_search_for(params[:search])
    elsif params[:tag].present?
      scope # 태그 필터가 있으면 전체 결과 표시
    else
      scope.where.not(id: id)
    end

    @pagy, @articles = pagy(article.includes(:user, :site).order(published_at: :desc))

    # 인기 태그 목록 (사이드바나 필터용)
    @popular_tags = Tag.popular_tags(20)
  end

  def show
    @comments = @article.comments.includes(:user).order(created_at: :desc)

    # Only load similar articles if embedding exists
    @similar_articles = if @article.embedding.present?
      Article.kept.where.not(id: @article.id)
             .nearest_neighbors(:embedding, @article.embedding, distance: "cosine", precision: "half")
             .limit(4)
    else
      Article.none
    end

    @comment = Comment.new
  end

  # GET /articles/new
  def new
    @article = Article.new(user: Current.user)
  end

  # POST /articles
  def create
    @article = Article.new(article_params.merge(origin_url: article_params[:url], user: Current.user))

    respond_to do |format|
      if @article.save
        format.html { redirect_to article_path(@article), notice: "Article was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      id = params[:id]
      return head :bad_request if id.blank?

      @article = Article.kept.find_by_slug(id) || Article.kept.find_by(id: id)
      raise ActiveRecord::RecordNotFound if @article.nil?
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.require(:article).permit(:url)
    rescue ActionController::ParameterMissing
      # Return empty parameters if article params are missing
      ActionController::Parameters.new({}).permit!
    end
end
