# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class FeedController < ApplicationController
  include Pundit::Authorization
  include Pagy::Method

  after_action :verify_authorized

  def show
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy

    @pagy, @posts = pagy(:countless, Feeds::Timeline.posts_for(current_user), limit: 20)

    render Views::Activities::Feed.new(
      posts: @posts,
      pagy: @pagy,
      liked_post_ids: Like.liked_ids_for(liker: current_user, likeable_type: "Post", likeable_ids: @posts.map(&:id)),
      boosted_post_ids: Boost.boosted_ids_for(booster: current_user, boostable_type: "Post", boostable_ids: @posts.map(&:id)),
      boosters_by_post_id: Feeds::Timeline.boosters_for(posts: @posts, user: current_user)
    )
  end

  private

  def pundit_user
    current_user
  end
end
