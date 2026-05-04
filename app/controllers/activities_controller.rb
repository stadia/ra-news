# app/controllers/activities_controller.rb
# frozen_string_literal: true

class ActivitiesController < ApplicationController
  include Pundit::Authorization
  include Pagy::Method

  after_action :verify_authorized

  before_action :authenticate_user!, only: [ :feed ]

  def index
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = policy_scope(Federails::Activity, policy_scope_class: Federails::Client::ActivityPolicy::Scope).all
    @activities = @activities.where(actor: Federails::Actor.find_param(params[:actor_id])) if params[:actor_id]
    render template: "federails/client/activities/index"
  end

  def feed
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    actor = current_user.federails_actor
    following_actor_ids = Federails::Following.accepted.where(actor: actor).select(:target_actor_id)

    posts = Post
      .includes(:user, :federails_actor, :article, :tags, parent: [ :user, :federails_actor ])
      .where(federails_actor_id: following_actor_ids)
      .or(Post.where(user_id: current_user.id))
      .order(created_at: :desc)

    @pagy, @posts = pagy(:countless, posts, limit: 20)
    @liked_post_ids = Like.liked_ids_for(
      liker: current_user,
      likeable_type: "Post",
      likeable_ids: @posts.map(&:id)
    )

    render Views::Activities::Feed.new(posts: @posts, pagy: @pagy, liked_post_ids: @liked_post_ids)
  end

  private

  def pundit_user
    current_user
  end
end
