# frozen_string_literal: true

# rbs_inline: enabled

class ProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by!(username: params[:username])
    actor = @user.federails_actor
    render Views::Profiles::Show.new(
      user: @user,
      actor: actor,
      followers_count: actor&.followers&.count || 0,
      following_count: actor&.follows&.count || 0
    )
  end
end
