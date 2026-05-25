# frozen_string_literal: true
# rbs_inline: enabled

module Resolvers
  class ArticleFeedResolver < GraphQL::Schema::Resolver
    type Types::ArticleFeedType, null: false

    argument :kind, Types::ArticleFeedKindEnum, required: true
    argument :search, String, required: false
    argument :keyword, String, required: false
    argument :page, String, required: false
    argument :limit, Integer, required: false

    #: (kind: String, ?search: String?, ?keyword: String?, ?page: String?, ?limit: Integer?) -> Hash[Symbol, untyped]
    def resolve(kind:, search: nil, keyword: nil, page: nil, limit: nil)
      relation = article_relation(kind:, search:, keyword:)
      pagy = Pagy::Keyset.new(
        relation.reorder(published_at: :desc, id: :desc),
        page:,
        limit: limit || Pagy::OPTIONS[:limit]
      )
      articles = pagy.records
      context[:liked_article_ids] = liked_article_ids(articles)

      {
        articles:,
        pagination: {
          page: pagy.page,
          next_page: pagy.next,
          limit: pagy.limit
        }
      }
    end

    private
      #: (kind: String, search: String?, keyword: String?) -> ActiveRecord::Relation
      def article_relation(kind:, search:, keyword:)
        case kind
        when "RELATED"
          Articles::Query.index_json(search)
        when "OTHERS"
          Articles::Query.others
        when "TAGGED"
          raise GraphQL::ExecutionError, "keyword is required for tagged article feed" if keyword.blank?

          Articles::Query.tagged(keyword)
        else
          raise GraphQL::ExecutionError, "unsupported article feed kind"
        end
      end

      #: (Array[Article]) -> Array[Integer]
      def liked_article_ids(articles)
        Like.liked_ids_for(
          liker: context[:current_user],
          likeable_type: "Article",
          likeable_ids: articles.map(&:id)
        )
      end
  end
end
