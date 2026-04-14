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

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback stores guild info in session and redirects to channels" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "access_token" => "bot-token-123",
      "guild" => { "id" => "G_SETUP", "name" => "Setup Guild" }
    }.with_indifferent_access

    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    assert_redirected_to discord_channels_path
  end

  test "GET channels redirects when session is empty" do
    sign_in_as(users(:john))

    get discord_channels_path

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 설정 정보가 없습니다. 다시 시도해 주세요.", flash[:alert]
  end

  test "POST setup creates DiscordChannel and redirects" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = { "access_token" => "bot-token", "guild" => { "id" => "G_SETUP2", "name" => "Setup Guild" } }.with_indifferent_access
    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    webhook_result = { id: "WH123", token: "whtoken", url: "https://discord.com/api/webhooks/WH123/whtoken" }
    channels_list = [ { "id" => "C_PICK", "name" => "al-news", "type" => 0 } ]

    DiscordClient.stub(:create_webhook, webhook_result) do
      DiscordClient.stub(:list_channels, channels_list) do
        post discord_setup_path, params: { channel_id: "C_PICK" }
      end
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 서버가 연결되었습니다.", flash[:notice]

    channel = DiscordChannel.find_by!(remote_id: "G_SETUP2")
    assert_equal "Setup Guild", channel.name
    assert_equal "https://discord.com/api/webhooks/WH123/whtoken", channel.webhook_url
    assert_equal "C_PICK", channel.channel_id
    assert_equal "al-news", channel.channel_name
  end
end
