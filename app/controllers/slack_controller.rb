# frozen_string_literal: true
# rbs_inline: enabled

class SlackController < ApplicationController
  protect_from_forgery except: [ :events, :callback ]
  skip_before_action :authenticate_user!
  before_action :verify_slack_signature, only: [ :events ]

  def install
    unless SlackConfig.configured?
      redirect_to edit_user_registration_path, alert: "Slack 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요."
      return
    end

    state = SecureRandom.hex(16)
    session[:slack_oauth_state] = state

    redirect_to SlackClient.authorize_url(
      redirect_uri: slack_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    stored_state = session.delete(:slack_oauth_state)
    incoming_state = params[:state]

    if stored_state.blank? || stored_state != incoming_state
      redirect_to oauth_result_path(provider: "slack", success: "false", error: "잘못된 인증 요청입니다."), allow_other_host: false
      return
    end

    oauth = SlackClient.exchange_code(params[:code], redirect_uri: slack_oauth_callback_url)
    team = oauth.fetch("team")
    incoming_webhook = oauth.fetch("incoming_webhook")

    channel = nil
    SlackChannel.transaction do
      channel = SlackChannel.find_or_initialize_by(remote_id: team.fetch("id"))
      channel.assign_attributes(
        name: team.fetch("name"),
        webhook_url: incoming_webhook.fetch("url"),
        channel_id: incoming_webhook.fetch("channel_id"),
        channel_name: incoming_webhook.fetch("channel"),
        status: :active,
        last_verified_at: Time.current
      )
      channel.save!
    end

    redirect_to oauth_result_path(provider: "slack", success: "true", channel_name: channel.channel_name)
  rescue KeyError, SlackClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to oauth_result_path(provider: "slack", success: "false", error: e.message)
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
    signing_secret = SlackConfig.signing_secret

    return head :unauthorized if timestamp.blank? || signature.blank?
    return head :unauthorized if signing_secret.blank?
    return head :unauthorized if (Time.zone.now.to_i - timestamp.to_i).abs > 300

    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
  end
end
