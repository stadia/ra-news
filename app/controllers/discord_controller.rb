# frozen_string_literal: true
# rbs_inline: enabled

class DiscordController < ApplicationController
  def install
    unless DiscordConfig.configured?
      redirect_to edit_user_registration_path, alert: "Discord 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요."
      return
    end

    state = SecureRandom.hex(16)
    session[:discord_oauth_state] = state

    redirect_to DiscordClient.authorize_url(
      redirect_uri: discord_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    stored_state = session.delete(:discord_oauth_state)
    incoming_state = params[:state]

    unless stored_state.present? && ActiveSupport::SecurityUtils.secure_compare(stored_state, incoming_state.to_s)
      redirect_to edit_user_registration_path, alert: "Discord 인증 상태가 일치하지 않습니다."
      return
    end

    oauth = DiscordClient.exchange_code(params[:code], redirect_uri: discord_oauth_callback_url)
    guild = oauth[:guild]
    webhook = oauth[:webhook]

    unless guild.present? && webhook.present?
      raise DiscordClient::ApiError, "Discord OAuth 응답에 webhook 정보가 없습니다."
    end

    guild_id = webhook[:guild_id].presence || guild[:id]
    webhook_url = webhook[:url]
    channel = DiscordChannel.find_or_initialize_by(remote_id: guild_id)
    channel.assign_attributes(
      name: guild[:name],
      webhook_url: webhook_url,
      channel_id: webhook[:channel_id],
      channel_name: webhook[:name].presence || "unknown",
      status: :active,
      last_verified_at: Time.current
    )

    begin
      DiscordChannel.transaction do
        channel.save!
      end
    rescue ActiveRecord::RecordInvalid
      cleanup_discord_webhook(webhook_url)
      raise
    end

    redirect_to edit_user_registration_path, notice: "Discord 서버가 연결되었습니다."
  rescue DiscordClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end

  private

  def cleanup_discord_webhook(webhook_url)
    return if webhook_url.blank?

    DiscordClient.delete_webhook(webhook_url)
  rescue DiscordClient::ApiError => e
    Rails.logger.warn("Failed to cleanup Discord webhook #{webhook_url}: #{e.message}")
  end
end
