# frozen_string_literal: true

require "test_helper"
require "uri"

class SlackControllerTest < ActionDispatch::IntegrationTest
  test "GET install redirects to slack authorize url" do
    sign_in_as(users(:john))

    SlackConfig.stub(:client_id, "client-123") do
      get slack_install_path
    end

    assert_response :redirect
    assert_includes response.location, "https://slack.com/oauth/v2/authorize"
    assert_includes response.location, "client_id=client-123"
  end

  test "GET callback upserts workspace and redirects to account page" do
    sign_in_as(users(:john))

    get slack_install_path
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "team" => { "id" => "TCALLBACK", "name" => "Callback Team" },
      "access_token" => "xoxb-callback",
      "bot_user_id" => "UBOTCALLBACK",
      "authed_user" => { "id" => "UJOHNCALLBACK" }
    }

    oauth_stub = Struct.new(:response) do
      def exchange_code(_code, redirect_uri:)
        response
      end
    end

    SlackOauthService.stub(:new, -> { oauth_stub.new(oauth_response) }) do
      get slack_oauth_callback_path, params: { code: "oauth-code", state: state }
    end

    assert_redirected_to edit_user_registration_path

    workspace = SlackWorkspace.find_by!(team_id: "TCALLBACK")
    assert_equal "Callback Team", workspace.team_name
    assert_equal "xoxb-callback", workspace.bot_access_token
    assert_equal "UBOTCALLBACK", workspace.bot_user_id
  end
end
