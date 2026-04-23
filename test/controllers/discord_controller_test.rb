# frozen_string_literal: true

require "test_helper"
require "uri"

class DiscordControllerTest < ActionDispatch::IntegrationTest
  test "GET install redirects with alert when not configured" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, false) do
      get discord_install_path
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요.", flash[:alert]
  end

  test "GET install redirects to Discord authorize url" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end

    assert_response :redirect
    assert_includes response.location, "discord.com/api/oauth2/authorize"
    assert_includes response.location, "client_id=dc-123"
  end

  test "GET callback rejects when state is invalid" do
    sign_in_as(users(:john))

    get discord_oauth_callback_path, params: { code: "oauth-code", state: "wrong" }

    assert_redirected_to oauth_result_path(provider: "discord", success: "false", error: "잘못된 인증 요청입니다.")
  end

  test "GET callback stores oauth webhook and redirects to result page" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "access_token" => "bot-token-123",
      "guild" => { "id" => "G_SETUP", "name" => "Setup Guild" },
      "webhook" => {
        "guild_id" => "G_SETUP",
        "channel_id" => "C_PICK",
        "name" => "al-news",
        "url" => "https://discord.com/api/webhooks/WH123/whtoken"
      }
    }.with_indifferent_access

    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    assert_redirected_to oauth_result_path(provider: "discord", success: "true", channel_name: "al-news")

    channel = DiscordChannel.find_by!(remote_id: "G_SETUP")

    assert_equal "Setup Guild", channel.name
    assert_equal "https://discord.com/api/webhooks/WH123/whtoken", channel.webhook_url
    assert_equal "C_PICK", channel.channel_id
    assert_equal "al-news", channel.channel_name
  end

  test "GET callback fails when oauth response has no webhook" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "access_token" => "oauth-token",
      "guild" => { "id" => "G_SETUP3", "name" => "Setup Guild" }
    }.with_indifferent_access
    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    assert_redirected_to oauth_result_path(provider: "discord", success: "false", error: "Discord OAuth 응답에 webhook 정보가 없습니다.")
  end
end
