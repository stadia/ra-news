# frozen_string_literal: true
# rbs_inline: enabled

class LongformPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [ :edit, :update, :publish, :destroy ]
  before_action :authorize_owner!, only: [ :edit, :update, :publish, :destroy ]

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

  private

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
