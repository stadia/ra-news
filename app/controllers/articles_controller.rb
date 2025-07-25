# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_article, only: %i[ show edit ]

  include Pagy::Backend

  # GET /articles or /articles.json
  def index
    article = if params[:search].present?
      Article.full_text_search_for(params[:search])
    else
      Article.where.not(id: Article.kept.select(:id).where.not(slug: nil).where(created_at: 24.hours.ago...).order(created_at: :desc).map(&:id))
    end
    @pagy, @articles = pagy(article.includes(:user).where.not(slug: nil).kept.order(published_at: :desc))
  end

  def show
    @comments = @article.comments.includes(:user).order(created_at: :desc)
    @similar_articles = Article.kept.where.not(id: @article.id).nearest_neighbors(:embedding, @article.embedding, distance: "cosine", precision: "half").first(3)
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
      @article = Article.kept.find_by_slug(params.expect(:id)) || Article.kept.find_by(id: params.expect(:id))
      raise ActiveRecord::RecordNotFound if @article.nil?
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.expect(article: [ :url ])
    end
end
