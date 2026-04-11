# frozen_string_literal: true

class SlackController < ApplicationController
  protect_from_forgery except: :events
  before_action :authenticate_user!, except: :events
  before_action :verify_slack_signature, only: :events

  def install
    unless SlackConfig.configured?
      redirect_to edit_user_registration_path, alert: "Slack 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요."
      return
    end

    state = SecureRandom.hex(16)
    session[:slack_oauth_state] = state

    redirect_to SlackOauthService.new.authorize_url(
      redirect_uri: slack_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    stored_state = session.delete(:slack_oauth_state)
    incoming_state = params[:state]

    if stored_state.blank? || incoming_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(stored_state, incoming_state)
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
  rescue KeyError, SlackClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Slack 연결에 실패했습니다: #{e.message}"
  end

  def events
    if params[:type] == "url_verification"
      render json: { challenge: params[:challenge] }
    else
      head :ok
    end
  end

  private

  def verify_slack_signature
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]

    return head :unauthorized if timestamp.blank? || signature.blank?
    return head :unauthorized if (Time.now.to_i - timestamp.to_i).abs > 300

    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", SlackConfig.signing_secret.to_s, sig_basestring)

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
  end
end
