# frozen_string_literal: true

class SlackController < ApplicationController
  protect_from_forgery except: :events
  before_action :authenticate_user!, except: :events

  def install
    state = SecureRandom.hex(16)
    session[:slack_oauth_state] = state

    redirect_to SlackOauthService.new.authorize_url(
      redirect_uri: slack_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    if params[:state] != session.delete(:slack_oauth_state)
      redirect_to edit_user_registration_path, alert: "Slack 인증 상태가 일치하지 않습니다."
      return
    end

    oauth = SlackOauthService.new.exchange_code(params[:code], redirect_uri: slack_oauth_callback_url)
    team = oauth.fetch("team")

    workspace = SlackWorkspace.find_or_initialize_by(team_id: team.fetch("id"))
    workspace.assign_attributes(
      team_name: team.fetch("name"),
      bot_access_token: oauth.fetch("access_token"),
      bot_user_id: oauth.fetch("bot_user_id"),
      status: :active,
      last_verified_at: Time.current
    )
    workspace.save!

    current_user.user_workspace_subscriptions.find_or_initialize_by(slack_workspace: workspace).tap do |subscription|
      subscription.slack_user_id ||= oauth.dig("authed_user", "id")
      subscription.save! if subscription.changed?
    end

    redirect_to edit_user_registration_path, notice: "Slack 워크스페이스가 연결되었습니다."
  rescue KeyError, SlackClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Slack 연결에 실패했습니다: #{e.message}"
  end

  def events
    if params[:type] == "url_verification"
      render json: { challenge: params[:challenge] }
    else
      head :ok
    end
  end
end
