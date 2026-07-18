# frozen_string_literal: true
# rbs_inline: enabled

class BlogPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]
  before_action :authorize_owner!, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]

  def index
    render Views::BlogPosts::Index.new(
      drafts: current_user.posts.blog.draft.kept.order(updated_at: :desc),
      published: current_user.posts.blog.published.kept.order(published_at: :desc),
      trash: current_user.posts.blog.discarded.order(updated_at: :desc)
    )
  end

  # Opens the editor for an unsaved draft. No row is created on entry — the
  # first autosave (or publish) persists it via #create.
  #
  # The composer POSTs the in-progress body here so it stays out of the URL; we
  # stash it in the cache under a per-request nonce and redirect to the GET
  # editor (Turbo follows the redirect and renders the page). Opening the editor
  # directly (GET) carries over that stashed body once, then starts fresh. The
  # nonce travels in the redirect URL query, so no session state is needed.
  def new
    if request.post?
      draft_key = SecureRandom.hex(8)
      # User-scoped key so one user can't read another's stashed body, plus a
      # TTL so abandoned drafts don't linger. The nonce keeps concurrent tabs
      # from clobbering each other.
      Rails.cache.write(blog_draft_cache_key(draft_key), params.dig(:post, :body).to_s, expires_in: 1.day)
      return redirect_to new_blog_post_path(draft_key: draft_key), status: :see_other
    end

    @post = current_user.posts.new(
      post_type: :blog,
      status: :draft,
      body: carried_over_draft_body
    )
    render Views::BlogPosts::Edit.new(post: @post)
  end

  def create
    @post = current_user.posts.new(blog_post_params)
    @post.post_type = :blog

    if publishing?
      @post.publish!
      redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.published")
    else
      @post.status = :draft
      @post.title = I18n.t("posts.blog.untitled_draft") if @post.title.blank?
      respond_to do |format|
        if @post.save
          format.json { render json: created_draft_payload }
          format.html { redirect_to edit_blog_post_path(@post) }
        else
          format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
          format.html { render Views::BlogPosts::Edit.new(post: @post), status: :unprocessable_entity }
        end
      end
    end
  rescue ActiveRecord::RecordInvalid
    render Views::BlogPosts::Edit.new(post: @post), status: :unprocessable_entity
  end

  def edit
    render Views::BlogPosts::Edit.new(post: @post)
  end

  def update
    if @post.update(blog_post_params)
      respond_to do |format|
        format.html { redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.updated") }
        format.json { render json: { status: "ok", saved_at: l(Time.current, format: :short) } }
      end
    else
      respond_to do |format|
        format.html { render Views::BlogPosts::Edit.new(post: @post), status: :unprocessable_entity }
        format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def publish
    @post.assign_attributes(blog_post_params) if params[:post].present?
    @post.publish!
    redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.published")
  rescue ActiveRecord::RecordInvalid
    render Views::BlogPosts::Edit.new(post: @post), status: :unprocessable_entity
  end

  def destroy
    # Soft-delete via Discard::Model keeps the record so federation/tombstone
    # lookups still resolve. The model's `after_discard` callback emits an
    # ActivityPub Delete for published posts; drafts never federated.
    @post.discard
    redirect_to feed_path, notice: t("posts.blog.deleted")
  end

  def undiscard
    # Restoring a published post re-federates via the model's after_undiscard
    # (Undo); drafts were never federated, so nothing is emitted for them.
    @post.undiscard
    redirect_to account_blog_path, notice: t("posts.blog.restored")
  end

  def destroy_permanently
    # Hard-destroy removes the row for good. Federails' after_destroy emits a
    # Delete for a published post; since trash items were already soft-discarded
    # (which emitted a Delete too), remotes may receive a duplicate Delete. That
    # is benign — the tombstone already exists remotely, so the second Delete is
    # idempotent.
    @post.destroy
    redirect_to account_blog_path, notice: t("posts.blog.destroyed_permanently")
  end

  private

  # Reads and consumes (one-shot) the body stashed by the composer's POST. A
  # missing nonce or cache miss (expired/consumed) yields a blank body so the
  # editor starts fresh.
  def carried_over_draft_body
    draft_key = params[:draft_key]
    return "" if draft_key.blank?

    key = blog_draft_cache_key(draft_key)
    body = Rails.cache.read(key)
    Rails.cache.delete(key)
    body.to_s
  end

  # Namespaced under the current user so a stashed body is only ever readable by
  # the account that wrote it (defense in depth against nonce guessing).
  def blog_draft_cache_key(draft_key)
    "blog_draft:#{current_user.id}:#{draft_key}"
  end

  # The publish button on an unsaved draft submits to #create with a publish
  # flag (HTML), so the draft is created and published in one request.
  def publishing?
    params[:publish].present? && !request.format.json?
  end

  # Tells the editor's autosave controller how to address the now-persisted
  # draft: switch from POST #create to PATCH #update and target the publish
  # route, all without a page reload.
  def created_draft_payload
    {
      status: "ok",
      saved_at: l(Time.current, format: :short),
      save_url: blog_post_path(@post, format: :json),
      form_url: blog_post_path(@post),
      publish_url: publish_blog_post_path(@post)
    }
  end

  # Discard adds no default scope, so undiscard/destroy_permanently must reach
  # soft-deleted rows. Every other action operates on live content only, so
  # restrict those to kept rows to avoid editing/publishing a trashed post.
  def set_post
    scope = Post.blog
    scope = scope.kept unless %w[undiscard destroy_permanently].include?(action_name)
    @post = scope.find_by!(slug: params[:id])
  end

  def authorize_owner!
    return if @post.user == current_user
    redirect_to feed_path, alert: t("posts.blog.forbidden")
  end

  def blog_post_params
    params.expect(post: [ :title, :body, :tag_list ])
  end
end
