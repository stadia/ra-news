# typed: true
# frozen_string_literal: true

require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
  test "GET result renders success page" do
    get "/slack/result?success=true&channel_name=general"

    assert_response :success
  end

  test "GET result renders error page" do
    get "/slack/result?success=false&error=access_denied"

    assert_response :success
  end

  test "GET install redirects with alert when Slack is not configured" do
    user = users(:john)
    sign_in_as(user)

    Configs::Slack.stub(:configured?, false) do
      get "/slack/install"

      assert_redirected_to edit_user_registration_path
    end
  end

  test "GET install redirects with alert when Discord is not configured" do
    user = users(:john)
    sign_in_as(user)

    Configs::Discord.stub(:configured?, false) do
      get "/discord/install"

      assert_redirected_to edit_user_registration_path
    end
  end

  test "GET install redirects with alert for unsupported provider" do
    get "/unknown/install"

    assert_redirected_to edit_user_registration_path
    assert_equal "지원하지 않는 연동입니다.", flash[:alert]
  end
end
