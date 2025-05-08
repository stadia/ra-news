# frozen_string_literal: true

# rbs_inline: enabled

class ArticlesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_article, only: %i[ show ]

  # GET /articles or /articles.json
  def index
    @articles = Article.all.order(id: :desc)
  end

  # GET /articles/1 or /articles/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params.expect(:id))
    end
end
