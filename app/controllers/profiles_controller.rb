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
    render Views::Profiles::FollowList.new(user: @user, actors: actors, type: :followers)
  end

  def following
    actor = @user.federails_actor
    actors = actor ? actor.follows.to_a : []
    render Views::Profiles::FollowList.new(user: @user, actors: actors, type: :following)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by!(username: params[:username])
    end
end
