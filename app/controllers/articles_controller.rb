# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_article, only: %i[ show edit update destroy ]

  include Pagy::Backend

  # GET /articles or /articles.json
  def index
    article = if params[:search].present?
      Article.full_text_search_for(params[:search])
    else
      Article.where.not(id: Article.select(:id).where(deleted_at: nil).limit(9).order(created_at: :desc).map(&:id))
    end
    @pagy, @articles = pagy(article.includes(:user).where(deleted_at: nil).order(published_at: :desc))
  end

  def show
  end

  # GET /articles/new
  def new
    @article = Article.new(user: Current.user)
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles
  def create
    @article = Article.new(article_params.merge(origin_url: article_params[:url], user: Current.user))

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: "Article was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: "Article was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  def destroy
    @article.destroy!

    respond_to do |format|
      format.html { redirect_to articles_path, status: :see_other, notice: "Article was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.where(deleted_at: nil).find_by!(slug: params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.expect(article: [ :url ])
    end
end
