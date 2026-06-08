# frozen_string_literal: true
# rbs_inline: enabled

class LongformPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]
  before_action :authorize_owner!, only: [ :edit, :update, :publish, :destroy, :undiscard, :destroy_permanently ]

  def create
    post = current_user.posts.create!(
      post_type: :longform,
      status: :draft,
      title: I18n.t("posts.longform.untitled_draft"),
      body: ""
    )
    redirect_to edit_longform_post_path(post)
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
    redirect_to user_profile_trash_path(username: current_user.username), notice: t("posts.longform.restored")
  end

  def destroy_permanently
    # Hard-destroy removes the row for good. For a published (still-federated)
    # post the model's after_discard already emitted a Delete on soft-discard;
    # destroying a kept published post here emits one now via the destroy hook.
    @post.destroy
    redirect_to user_profile_trash_path(username: current_user.username), notice: t("posts.longform.destroyed_permanently")
  end

  private

  # Discard adds no default scope, so find_by! locates kept AND discarded rows.
  # This lets undiscard/destroy_permanently operate on soft-deleted posts.
  def set_post
    @post = Post.longform.find_by!(slug: params[:id])
  end

  def authorize_owner!
    return if @post.user == current_user
    redirect_to feed_path, alert: t("posts.longform.forbidden")
  end

  def longform_post_params
    params.expect(post: [ :title, :body, :tag_list ])
  end
end
