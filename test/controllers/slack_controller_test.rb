# frozen_string_literal: true

require "test_helper"
require "uri"

class SlackControllerTest < ActionDispatch::IntegrationTest
  test "GET install redirects to slack authorize url" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) do
      SlackConfig.stub(:client_id, "client-123") do
        get slack_install_path
      end
    end

    assert_response :redirect
    assert_includes response.location, "https://slack.com/oauth/v2/authorize"
    assert_includes response.location, "client_id=client-123"
  end

  test "GET install redirects with alert when not configured" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, false) do
      get slack_install_path
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요.", flash[:alert]
  end

  test "GET callback rejects when state param is missing" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) { get slack_install_path }

    get slack_oauth_callback_path, params: { code: "oauth-code" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback rejects when session state is missing" do
    sign_in_as(users(:john))

    get slack_oauth_callback_path, params: { code: "oauth-code", state: "some-state" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback rejects when both state values are empty" do
    sign_in_as(users(:john))

    get slack_oauth_callback_path, params: { code: "oauth-code", state: "" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback upserts workspace and redirects to account page" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) { get slack_install_path }
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "team" => { "id" => "TCALLBACK", "name" => "Callback Team" },
      "access_token" => "xoxb-callback",
      "bot_user_id" => "UBOTCALLBACK",
      "authed_user" => { "id" => "UJOHNCALLBACK" }
    }

    SlackOauth.stub(:exchange_code, oauth_response) do
      get slack_oauth_callback_path, params: { code: "oauth-code", state: state }
    end

    assert_redirected_to edit_user_registration_path

    workspace = SlackWorkspace.find_by!(team_id: "TCALLBACK")

    assert_equal "Callback Team", workspace.team_name
    assert_equal "xoxb-callback", workspace.bot_access_token
    assert_equal "UBOTCALLBACK", workspace.bot_user_id
  end
end
