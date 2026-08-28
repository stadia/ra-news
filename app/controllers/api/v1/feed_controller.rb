# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::FeedController < Api::V1::BaseController
  include Pundit::Authorization
  include Pagy::Method

  after_action :verify_authorized

  def show
    authorize Fedipub::Activity, policy_class: Fedipub::Client::ActivityPolicy

    pagy, posts = pagy(:countless, Feeds::Timeline.posts_for(current_user), limit: 20)

    render json: {
      posts: PostSerializer.new(posts, params: {
        liked_ids: Like.liked_ids_for(liker: current_user, likeable_type: "Post", likeable_ids: posts.map(&:id)),
        boosted_ids: Boost.boosted_ids_for(booster: current_user, boostable_type: "Post", boostable_ids: posts.map(&:id)),
        boosters_by_post_id: Feeds::Timeline.boosters_for(posts:, user: current_user)
      }).serializable_hash,
      pagination: {
        next_page: pagy.next,
        limit: pagy.limit
      }
    }
  end

  private

  def pundit_user
    current_user
  end
end
