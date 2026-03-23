# frozen_string_literal: true

# rbs_inline: enabled

class ProfilesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_user

  def show
    actor = @user.federails_actor
    render Views::Profiles::Show.new(
      user: @user,
      actor: actor,
      followers_count: actor&.followers&.count || 0,
      following_count: actor&.follows&.count || 0
    )
  end

  def followers
    actor = @user.federails_actor
    followings = actor ? actor.following_followers.to_a : []
    render_follow_page(actor, followings, :followers)
  end

  def following
    actor = @user.federails_actor
    followings = actor ? actor.following_follows.to_a : []
    render_follow_page(actor, followings, :following)
  end

  private

    def set_user
      @user = User.find_by!(username: params[:username])
    end

    def render_follow_page(actor, followings, type)
      if turbo_frame_request?
        render Views::Profiles::FollowList.new(user: @user, followings: followings, type: type)
      else
        render Views::Profiles::Show.new(
          user: @user,
          actor: actor,
          followers_count: actor&.followers&.count || 0,
          following_count: actor&.follows&.count || 0,
          follow_actors: followings,
          follow_type: type
        )
      end
    end
end
