# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_article, only: %i[ show ]

  # GET /articles or /articles.json
  def index
    @articles = Article.where(deleted_at: nil).all.order(published_at: :desc, id: :desc)
  end

  # GET /articles/1 or /articles/1.json
  def show
  end

  def new
    @article = Article.new(user: Current.user)
  end

  def create
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.where(deleted_at: nil).find(params.expect(:id))
    end
end
