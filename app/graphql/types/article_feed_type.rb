# frozen_string_literal: true

module Types
  class ArticleFeedType < Types::BaseObject
    field :articles, [Types::ArticleType], null: false
    field :pagination, Types::PaginationType, null: false
  end
end
