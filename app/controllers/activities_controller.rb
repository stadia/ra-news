# frozen_string_literal: true
# rbs_inline: enabled

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

    boosted_post_ids = Boost
      .where(boostable_type: "Post", actor_id: following_actor_ids)
      .or(Boost.where(boostable_type: "Post", actor_id: actor.id))
      .select(:boostable_id)

    posts = Post
      .includes(:user, :federails_actor, :article, :tags, parent: [ :user, :federails_actor ])
      .where(federails_actor_id: following_actor_ids)
      .or(Post.where(user_id: current_user.id))
      .or(Post.where(id: boosted_post_ids))
      .visible
      .order(created_at: :desc)

    @pagy, @posts = pagy(:countless, posts, limit: 20)
    @liked_post_ids = Like.liked_ids_for(
      liker: current_user,
      likeable_type: "Post",
      likeable_ids: @posts.map(&:id)
    )
    @boosted_post_ids = Boost.boosted_ids_for(
      booster: current_user,
      boostable_type: "Post",
      boostable_ids: @posts.map(&:id)
    )
    @boosters_by_post_id = boosters_for_attribution(@posts, actor, following_actor_ids)

    render Views::Activities::Feed.new(
      posts: @posts,
      pagy: @pagy,
      liked_post_ids: @liked_post_ids,
      boosted_post_ids: @boosted_post_ids,
      boosters_by_post_id: @boosters_by_post_id
    )
  end

  private

  def pundit_user
    current_user
  end

  # Returns a hash of { post_id => Federails::Actor } for posts that landed in
  # the feed because someone the current user follows (or the user themselves)
  # boosted them. Posts authored by the current user or by a followed actor are
  # excluded — they would have shown up regardless of any boost.
  def boosters_for_attribution(posts, actor, following_actor_ids)
    return {} if posts.blank?

    following_id_list = following_actor_ids.to_a
    candidate_actor_ids = following_id_list + [ actor.id ]

    attribution_post_ids = posts.reject { |post|
      post.user_id == current_user.id ||
        (post.federails_actor_id.present? && candidate_actor_ids.include?(post.federails_actor_id))
    }.map(&:id)

    return {} if attribution_post_ids.empty?

    Boost
      .where(boostable_type: "Post", boostable_id: attribution_post_ids, actor_id: candidate_actor_ids)
      .order(created_at: :desc)
      .includes(:actor)
      .each_with_object({}) do |boost, memo|
        memo[boost.boostable_id] ||= boost.actor
      end
  end
end
