# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_article, only: %i[ show edit ]

  include Pagy::Backend

  # GET /articles or /articles.json
  def index
    scope = Article.kept.confirmed

    article = if params[:search].present?
      scope.full_text_search_for(params[:search])
    else
      article_count = scope.where(created_at: 24.hours.ago...).order(created_at: :desc).count
      id = if article_count < 9
        scope.select(:id).limit(9).order(created_at: :desc).map(&:id)
      else
        scope.select(:id).where(created_at: 24.hours.ago...).order(created_at: :desc).map(&:id)
      end
      scope.where.not(id: id)
    end
    @pagy, @articles = pagy(article.includes(:user, :site).order(published_at: :desc))
  end

  def show
    @comments = @article.comments.includes(:user).order(created_at: :desc)

    # Only load similar articles if embedding exists
    @similar_articles = if @article.embedding.present?
      Article.kept.confirmed.where.not(id: @article.id)
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
        ArticleJob.perform_later(@article.id)
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
