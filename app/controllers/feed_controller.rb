# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class FeedController < ApplicationController
  include Pundit::Authorization
  include Pagy::Method

  after_action :verify_authorized

  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }, only: [ :show ]

  def show
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    actor = current_user.federails_actor
    following_actor_ids = Federails::Following.accepted.where(actor: actor).select(:target_actor_id)
    local_actor_ids = Federails::Actor.local.select(:id)

    boosted_post_ids = Boost
      .where(boostable_type: "Post", actor_id: following_actor_ids)
      .or(Boost.where(boostable_type: "Post", actor_id: actor.id))
      .select(:boostable_id)

    posts = Post
      .includes(:user, :federails_actor, :article, :tags, parent: [ :user, :federails_actor ])
      .where(federails_actor_id: following_actor_ids)
      .or(Post.where(federails_actor_id: local_actor_ids))
      .or(Post.where(user_id: current_user.id))
      .or(Post.where(id: boosted_post_ids))
      .visible
      .order(created_at: :desc)

    @pagy, @posts = pagy(:countless, posts, limit: 20)
    @boosters_by_post_id = boosters_for_attribution(@posts, actor, following_actor_ids)

    respond_to do |format|
      format.html do
        @liked_post_ids = liked_post_ids(@posts)
        @boosted_post_ids = boosted_post_ids(@posts)

        render Views::Activities::Feed.new(
          posts: @posts,
          pagy: @pagy,
          liked_post_ids: @liked_post_ids,
          boosted_post_ids: @boosted_post_ids,
          boosters_by_post_id: @boosters_by_post_id
        )
      end
      format.json do
        render json: serialize_collection(@posts, @pagy, @boosters_by_post_id)
      end
    end
  end

  private

  def pundit_user
    current_user
  end

  #: (ActiveRecord::Relation posts, Pagy pagy, Hash[Integer, Federails::Actor] boosters) -> Hash[Symbol, untyped]
  def serialize_collection(posts, pagy, boosters)
    {
      posts: PostSerializer.new(posts, params: {
        liked_ids: liked_post_ids(posts),
        boosted_ids: boosted_post_ids(posts),
        boosters_by_post_id: boosters
      }).serializable_hash,
      pagination: {
        next_page: pagy.next,
        limit: pagy.limit
      }
    }
  end

  #: (ActiveRecord::Relation posts) -> Array[Integer]
  def liked_post_ids(posts)
    Like.liked_ids_for(
      liker: current_user,
      likeable_type: "Post",
      likeable_ids: posts.map(&:id)
    )
  end

  #: (ActiveRecord::Relation posts) -> Array[Integer]
  def boosted_post_ids(posts)
    Boost.boosted_ids_for(
      booster: current_user,
      boostable_type: "Post",
      boostable_ids: posts.map(&:id)
    )
  end

  # Returns a hash of { post_id => Federails::Actor } for posts that landed in
  # the feed because someone the current user follows (or the user themselves)
  # boosted them. Posts authored by the current user, by a followed actor, or by
  # a local actor are excluded — they would have shown up regardless of any boost.
  #: (untyped posts, Federails::Actor actor, untyped following_actor_ids) -> Hash[Integer, Federails::Actor]
  def boosters_for_attribution(posts, actor, following_actor_ids)
    return {} if posts.blank?

    following_id_list = following_actor_ids.to_a
    candidate_actor_ids = following_id_list + [ actor.id ]

    attribution_post_ids = posts.reject { |post|
      post.user_id == current_user.id ||
        post.federails_actor&.local? ||
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
