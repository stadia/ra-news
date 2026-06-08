# frozen_string_literal: true
# rbs_inline: enabled

class PostsController < ApplicationController
  include RateLimiting

  before_action :authenticate_user!, only: [ :create, :destroy ]
  before_action :set_article, only: [ :create, :destroy ], if: -> { params[:article_id].present? }
  before_action :set_post, only: [ :destroy ]
  before_action :check_rate_limit, only: [ :create ]

  def show
    post = Post.includes(:user, :federails_actor, :article, :tags, parent: [ :user, :federails_actor ]).find_by!(slug: params[:id])
    raise ActiveRecord::RecordNotFound unless viewable?(post)
    root = post.root
    @posts = build_thread(root)
    @liked_post_ids = current_user ? Like.liked_ids_for(liker: current_user, likeable_type: "Post", likeable_ids: @posts.map(&:id)) : []
    @boosted_post_ids = current_user ? Boost.boosted_ids_for(booster: current_user, boostable_type: "Post", boostable_ids: @posts.map(&:id)) : []
    render Views::Posts::Show.new(posts: @posts, liked_post_ids: @liked_post_ids, boosted_post_ids: @boosted_post_ids)
  end

  def create
    if @article
      create_article_comment
    else
      create_standalone_post
    end
  end

  def destroy
    if @post.user != current_user
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "권한이 없습니다." }
        format.turbo_stream { head :unauthorized }
      end
      return
    end

    @article = @post.article
    @post.destroy

    if @article
      load_article_comments
      respond_to do |format|
        format.html { redirect_to @article, notice: "댓글이 삭제되었습니다." }
        format.turbo_stream { render "posts/destroy_article_comment" }
      end
    else
      respond_to do |format|
        format.html { redirect_to feed_path, notice: "포스트가 삭제되었습니다." }
        format.turbo_stream
      end
    end
  end

  private

  def create_article_comment
    @post = @article.posts.build(article_comment_params.merge(post_type: :comment, status: :published))
    @post.user = current_user
    @post.published_at ||= Time.current

    respond_to do |format|
      if @post.save
        load_article_comments
        format.html { redirect_to @article, notice: "댓글이 성공적으로 작성되었습니다." }
        format.turbo_stream { render "posts/create_article_comment" }
      else
        load_article_comments
        format.html { redirect_to @article, alert: "댓글 작성에 실패했습니다." }
        format.turbo_stream { render "posts/create_article_comment", status: :unprocessable_entity }
      end
    end
  end

  def create_standalone_post
    @post = current_user.posts.build(normalized_post_params)
    @post.post_type = :short
    @post.status = :published
    @post.published_at ||= Time.current

    respond_to do |format|
      if @post.save
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post) }
        format.html { redirect_to feed_path }
      else
        format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post), status: :unprocessable_entity }
        format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
      end
    end
  end

  def set_article
    @article = Article.kept.find_by_slug(params[:article_id]) || Article.kept.find_by(id: params[:article_id])
    raise ActiveRecord::RecordNotFound if @article.nil?
  end

  def set_post
    @post = Post.find_by!(slug: params[:id])
  end

  def load_article_comments
    @comments = @article.posts.kept.includes(:user)
  end

  # A post is publicly viewable when it is visible (published & kept). The owner
  # may also preview their own non-published (draft) post. Discarded posts are
  # never served here — the owner reaches them only via the profile trash tab.
  def viewable?(post)
    return true if post.kept? && post.published?
    return true if post.kept? && current_user && post.user == current_user

    false
  end

  def article_comment_params
    params.expect(post: [ :body, :parent_id ])
  end

  def post_params
    params.expect(post: [ :body, :parent_id, :tag_list ])
  end

  def normalized_post_params
    attributes = post_params.to_h.symbolize_keys
    attributes[:body] = reply_body_with_mention(body: attributes[:body], parent_id: attributes[:parent_id])
    attributes
  end

  def reply_body_with_mention(body:, parent_id:)
    return body if parent_id.blank?

    parent = Post.includes(:user, :federails_actor).find_by(id: parent_id)
    actor = parent&.user&.federails_actor || parent&.federails_actor
    return body if actor.nil? || actor.profile_url.blank?

    return body if body.to_s.include?(actor.profile_url)

    mention_candidates = [ actor.short_at_address, actor.at_address ].compact.uniq

    mention_candidates.each do |mention_text|
      next unless body.to_s.include?(mention_text)

      return body.to_s.sub(mention_text, mention_link_for(actor, mention_text))
    end

    "#{mention_link_for(actor, default_mention_text_for(actor))} #{body}".strip
  end

  def mention_link_for(actor, text)
    helpers.link_to(text, actor.profile_url).to_s
  end

  def default_mention_text_for(actor)
    actor.local? ? actor.short_at_address : actor.at_address
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
    Post.kept.where(id: ids).includes(:user, :federails_actor, :article, :tags, parent: [ :user, :federails_actor ]).sort_by { |p| [ p.depth, p.created_at ] }
  end
end
