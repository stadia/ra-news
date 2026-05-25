# frozen_string_literal: true

module Types
  class ArticleType < Types::BaseObject
    field :slug, String, null: true
    field :title, String, null: true
    field :title_ko, String, null: true
    field :url, String, null: true
    field :host, String, null: true
    field :is_related, Boolean, null: false
    field :likers_count, Integer, null: false
    field :posts_count, Integer, null: false
    field :summary_key, GraphQL::Types::JSON, null: true
    field :tags, [ String ], null: false
    field :liked, Boolean, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def tags
      object.tags.map(&:name)
    end

    def liked
      context[:liked_article_ids]&.include?(object.id) || false
    end
  end
end
