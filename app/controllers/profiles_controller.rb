# frozen_string_literal: true

# rbs_inline: enabled

class ProfilesController < ApplicationController
  allow_unauthenticated_access

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
    actors = actor ? actor.followers.to_a : []
    render_follow_page(actor, actors, :followers)
  end

  def following
    actor = @user.federails_actor
    actors = actor ? actor.follows.to_a : []
    render_follow_page(actor, actors, :following)
  end

  private

    def set_user
      @user = User.find_by!(username: params[:username])
    end

    def render_follow_page(actor, actors, type)
      if turbo_frame_request?
        render Views::Profiles::FollowList.new(user: @user, actors: actors, type: type)
      else
        render Views::Profiles::Show.new(
          user: @user,
          actor: actor,
          followers_count: actor&.followers&.count || 0,
          following_count: actor&.follows&.count || 0,
          follow_actors: actors,
          follow_type: type
        )
      end
    end
end
