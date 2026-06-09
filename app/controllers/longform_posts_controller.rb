# frozen_string_literal: true
# rbs_inline: enabled

class LongformPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_new_post, only: [ :new ]
  before_action :set_post, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]
  before_action :authorize_owner!, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]

  # Opens the editor for an unsaved draft. No row is created on entry — the
  # first autosave (or publish) persists it via #create. A body carried over
  # from the composer is prefilled so the in-progress text is not lost.
  def new
    render Views::LongformPosts::Edit.new(post: @post)
  end

  def create
    @post = current_user.posts.new(longform_post_params)
    @post.post_type = :longform

    if publishing?
      @post.publish!
      redirect_to post_path(@post), notice: t("posts.longform.published")
    else
      @post.status = :draft
      @post.title = I18n.t("posts.longform.untitled_draft") if @post.title.blank?
      respond_to do |format|
        if @post.save
          format.json { render json: created_draft_payload }
          format.html { redirect_to edit_longform_post_path(@post) }
        else
          format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
          format.html { render Views::LongformPosts::Edit.new(post: @post), status: :unprocessable_entity }
        end
      end
    end
  rescue ActiveRecord::RecordInvalid
    render Views::LongformPosts::Edit.new(post: @post), status: :unprocessable_entity
  end

  def edit
    render Views::LongformPosts::Edit.new(post: @post)
  end

  def update
    if @post.update(longform_post_params)
      respond_to do |format|
        format.html { redirect_to post_path(@post), notice: t("posts.longform.updated") }
        format.json { render json: { status: "ok", saved_at: l(Time.current, format: :short) } }
      end
    else
      respond_to do |format|
        format.html { render Views::LongformPosts::Edit.new(post: @post), status: :unprocessable_entity }
        format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def publish
    @post.assign_attributes(longform_post_params) if params[:post].present?
    @post.publish!
    redirect_to post_path(@post), notice: t("posts.longform.published")
  rescue ActiveRecord::RecordInvalid
    render Views::LongformPosts::Edit.new(post: @post), status: :unprocessable_entity
  end

  def destroy
    # Soft-delete via Discard::Model keeps the record so federation/tombstone
    # lookups still resolve. The model's `after_discard` callback emits an
    # ActivityPub Delete for published posts; drafts never federated.
    @post.discard
    redirect_to feed_path, notice: t("posts.longform.deleted")
  end

  def undiscard
    # Restoring a published post re-federates via the model's after_undiscard
    # (Undo); drafts were never federated, so nothing is emitted for them.
    @post.undiscard
    redirect_to user_profile_longform_path(username: current_user.username), notice: t("posts.longform.restored")
  end

  def destroy_permanently
    # Hard-destroy removes the row for good. Federails' after_destroy emits a
    # Delete for a published post; since trash items were already soft-discarded
    # (which emitted a Delete too), remotes may receive a duplicate Delete. That
    # is benign — the tombstone already exists remotely, so the second Delete is
    # idempotent.
    @post.destroy
    redirect_to user_profile_longform_path(username: current_user.username), notice: t("posts.longform.destroyed_permanently")
  end

  private

  def build_new_post
    @post = current_user.posts.new(
      post_type: :longform,
      status: :draft,
      body: params.dig(:post, :body).to_s
    )
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
      save_url: longform_post_path(@post, format: :json),
      form_url: longform_post_path(@post),
      publish_url: publish_longform_post_path(@post)
    }
  end

  # Discard adds no default scope, so undiscard/destroy_permanently must reach
  # soft-deleted rows. Every other action operates on live content only, so
  # restrict those to kept rows to avoid editing/publishing a trashed post.
  def set_post
    scope = Post.longform
    scope = scope.kept unless %w[undiscard destroy_permanently].include?(action_name)
    @post = scope.find_by!(slug: params[:id])
  end

  def authorize_owner!
    return if @post.user == current_user
    redirect_to feed_path, alert: t("posts.longform.forbidden")
  end

  def longform_post_params
    params.expect(post: [ :title, :body, :tag_list ])
  end
end
