# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::ArticlesController < Api::V1::BaseController
  include Pagy::Method

  skip_before_action :authenticate_user!, only: %i[index others tag]

  def index
    @pagy, @articles = pagy(:keyset, Articles::Query.index_json(params[:search]))
    render json: serialize_collection(@articles, @pagy)
  end

  def others
    @pagy, @articles = pagy(:keyset, Articles::Query.others)
    render json: serialize_collection(@articles, @pagy)
  end

  def tag
    @pagy, @articles = pagy(:keyset, Articles::Query.tagged(params[:keyword].to_s))
    render json: serialize_collection(@articles, @pagy)
  end

  private
    def serialize_collection(articles, pagy)
      {
        articles: ArticleSerializer.new(articles, params: {
          liked_ids: liked_article_ids(articles),
          boosted_ids: boosted_article_ids(articles)
        }).serializable_hash,
        pagination: {
          page: pagy.page,
          next_page: pagy.next,
          limit: pagy.limit
        }
      }
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
end
