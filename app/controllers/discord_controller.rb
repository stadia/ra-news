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

    if stored_state.blank? || incoming_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(stored_state, incoming_state)
      redirect_to edit_user_registration_path, alert: "Discord 인증 상태가 일치하지 않습니다."
      return
    end

    oauth = DiscordClient.exchange_code(params[:code], redirect_uri: discord_oauth_callback_url)
    guild = oauth[:guild]

    session[:discord_guild_id] = guild[:id]
    session[:discord_guild_name] = guild[:name]
    session[:discord_bot_token] = oauth[:access_token]

    redirect_to discord_channels_path
  rescue DiscordClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end

  def channels
    bot_token = session[:discord_bot_token]
    guild_id = session[:discord_guild_id]

    if bot_token.blank? || guild_id.blank?
      redirect_to edit_user_registration_path, alert: "Discord 설정 정보가 없습니다. 다시 시도해 주세요."
      return
    end

    channels = DiscordClient.list_channels(bot_token, guild_id)
    guild_name = session[:discord_guild_name]

    render Views::Discord::Channels.new(guild_name:, channels:)
  rescue DiscordClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Discord 채널 목록 조회에 실패했습니다: #{e.message}"
  end

  def setup
    bot_token = session[:discord_bot_token]
    guild_id = session[:discord_guild_id]
    guild_name = session[:discord_guild_name]
    channel_id = params[:channel_id]

    if bot_token.blank? || guild_id.blank? || channel_id.blank?
      redirect_to edit_user_registration_path, alert: "Discord 설정 정보가 없습니다. 다시 시도해 주세요."
      return
    end

    webhook = DiscordClient.create_webhook(bot_token, channel_id)

    channels_list = DiscordClient.list_channels(bot_token, guild_id)
    channel_info = channels_list.find { |c| c["id"] == channel_id }
    channel_name = channel_info&.dig("name") || "unknown"

    DiscordChannel.transaction do
      channel = DiscordChannel.find_or_initialize_by(remote_id: guild_id)
      channel.assign_attributes(
        name: guild_name,
        webhook_url: webhook[:url],
        channel_id: channel_id,
        channel_name: channel_name,
        status: :active,
        last_verified_at: Time.current
      )
      channel.save!
    end

    session.delete(:discord_guild_id)
    session.delete(:discord_guild_name)
    session.delete(:discord_bot_token)

    redirect_to edit_user_registration_path, notice: "Discord 서버가 연결되었습니다."
  rescue DiscordClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end
end
