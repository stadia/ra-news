# frozen_string_literal: true
# rbs_inline: enabled

class ArticleSerializer
  include Alba::Resource
  attributes :slug, :title, :title_ko, :url, :host,
             :is_related, :likers_count, :posts_count,
             :published_at, :created_at, :updated_at

  attribute :summary_key, &:summary_key
  attribute :tags do |article|
    article.tags.map(&:name)
  end
  attribute :liked do |article|
    params[:liked_ids]&.include?(article.id) || false
  end
  attribute :boosted do |article|
    params[:boosted_ids]&.include?(article.id) || false
  end
  attribute :boosts_count do |article|
    article.boosts_count
  end
end
