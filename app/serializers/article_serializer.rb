# frozen_string_literal: true

class ArticleSerializer
  include Alba::Resource
  attributes :slug, :title, :title_ko, :url, :host,
             :is_related, :likers_count, :posts_count,
             :published_at, :created_at, :updated_at

  attribute :summary_key, &:summary_key
  attribute :tags, &:tag_list
end
