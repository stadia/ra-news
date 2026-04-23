# frozen_string_literal: true
# rbs_inline: enabled

class OauthController < ApplicationController
  skip_before_action :authenticate_user!

  def result
    @provider = params[:provider]
    @success = params[:success] == "true"
    @channel_name = params[:channel_name]
    @error = params[:error]
    render Views::Oauth::Result.new(
      provider: @provider,
      success: @success,
      channel_name: @channel_name,
      error: @error
    )
  end
end
