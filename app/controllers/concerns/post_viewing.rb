# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

# Shared "render a post thread" behavior for the two controllers that serve a
# single post's reading page: PostsController (short/comment posts at
# /posts/:slug) and BlogsController (blog posts at /@user/blog/:slug).
module PostViewing
  extend ActiveSupport::Concern

  POST_SHOW_INCLUDES = [ :user, :federails_actor, :article, :tags, { parent: [ :user, :federails_actor ] } ].freeze

  private

  # Renders the reading page for +post+, or 404s if it is not viewable.
  def render_post_show(post)
    raise ActiveRecord::RecordNotFound unless viewable?(post)
    @posts = build_thread(post.root)
    @liked_post_ids = current_user ? Like.liked_ids_for(liker: current_user, likeable_type: "Post", likeable_ids: @posts.map(&:id)) : []
    @boosted_post_ids = current_user ? Boost.boosted_ids_for(booster: current_user, boostable_type: "Post", boostable_ids: @posts.map(&:id)) : []
    render Views::Posts::Show.new(posts: @posts, liked_post_ids: @liked_post_ids, boosted_post_ids: @boosted_post_ids)
  end

  # A post is publicly viewable when visible (published & kept). The owner may
  # also preview their own draft. Discarded posts are never served here.
  def viewable?(post)
    return true if post.kept? && post.published?
    return true if post.kept? && current_user && post.user == current_user

    false
  end

  def build_thread(root)
    # parent_id 기반으로 안전하게 스레드 수집
    ids = [ root.id ]
    queue = [ root.id ]
    while queue.any?
      children = Post.kept.where(parent_id: queue).pluck(:id)
      ids.concat(children)
      queue = children
    end
    Post.kept.where(id: ids).includes(POST_SHOW_INCLUDES).sort_by { |p| [ p.depth, p.created_at ] }
  end
end
