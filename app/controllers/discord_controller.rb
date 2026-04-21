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

    oauth = DiscordClient.exchange_code(params[:code], redirect_uri: discord_oauth_callback_url)
    guild = oauth[:guild]

    session[:discord_guild_id] = guild[:id]
    session[:discord_guild_name] = guild[:name]
    session[:discord_oauth_token] = oauth[:access_token]

    redirect_to discord_channels_path
  rescue DiscordClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end

  def channels
    bot_token = discord_bot_token
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
    bot_token = discord_bot_token
    guild_id = session[:discord_guild_id]
    guild_name = session[:discord_guild_name]
    channel_id = params[:channel_id]

    if bot_token.blank? || guild_id.blank? || channel_id.blank?
      redirect_to edit_user_registration_path, alert: "Discord 설정 정보가 없습니다. 다시 시도해 주세요."
      return
    end

    channels_list = DiscordClient.list_channels(bot_token, guild_id)
    channel_info = channels_list.find { |c| c["id"] == channel_id }

    if channel_info.nil?
      redirect_to edit_user_registration_path, alert: "유효하지 않은 채널입니다."
      return
    end

    channel_name = channel_info.dig("name") || params[:channel_name].presence || "unknown"
    channel = DiscordChannel.find_or_initialize_by(remote_id: guild_id)
    channel.assign_attributes(
      name: guild_name,
      channel_id: channel_id,
      channel_name: channel_name,
      status: :active,
      last_verified_at: Time.current
    )

    webhook_url = DiscordClient.create_webhook(bot_token, channel_id)[:url]
    channel.webhook_url = webhook_url

    begin
      DiscordChannel.transaction do
        channel.save!
      end
    rescue ActiveRecord::RecordInvalid
      cleanup_discord_webhook(webhook_url)
      raise
    end

    clear_discord_session!

    redirect_to edit_user_registration_path, notice: "Discord 서버가 연결되었습니다."
  rescue DiscordClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end

  private

  def discord_bot_token
    DiscordConfig.bot_token
  end

  def clear_discord_session!
    session.delete(:discord_guild_id)
    session.delete(:discord_guild_name)
    session.delete(:discord_oauth_token)
  end

  def cleanup_discord_webhook(webhook_url)
    return if webhook_url.blank?

    DiscordClient.delete_webhook(webhook_url)
  rescue DiscordClient::ApiError => e
    Rails.logger.warn("Failed to cleanup Discord webhook #{webhook_url}: #{e.message}")
  end
end
