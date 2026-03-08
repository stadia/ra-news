# frozen_string_literal: true

# rbs_inline: enabled

class ProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by!(username: params[:username])
    render Views::Profiles::Show.new(user: @user, actor: @user.federails_actor)
  end
end
