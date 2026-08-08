# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class PostSerializer
  include Alba::Resource
  attributes :id, :slug, :body, :post_type, :status,
             :created_at, :updated_at,
             :likes_count, :boosts_count

  attribute :liked do |post|
    params[:liked_ids]&.include?(post.id) || false
  end

  attribute :boosted do |post|
    params[:boosted_ids]&.include?(post.id) || false
  end

  attribute :author_name do |post|
    post.author_name
  end

  attribute :author_host do |post|
    post.author_host
  end

  attribute :author_avatar_url do |post|
    post.user&.avatar_url || post.federails_actor&.extensions&.dig("icon", "url")
  end

  attribute :article_slug do |post|
    post.article&.slug
  end

  attribute :parent_slug do |post|
    post.parent&.slug
  end

  attribute :boosted_by do |post|
    params[:boosters_by_post_id]&.dig(post.id)&.username
  end

  attribute :media_attachments do |post|
    post.media_attachments
  end
end
