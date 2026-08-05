# typed: true
# frozen_string_literal: true

require "test_helper"

class Users::OauthRegistrationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests Users::OauthRegistrationsController

  test "GET new는 oauth signup session이 있으면 화면을 렌더링한다" do
    @request.session[:oauth_signup] = oauth_signup_session

    get :new

    assert_response :success
    assert_select "input[name='user[username]']"
    assert_select "input[type='email'][value='oauth@example.com']"
  end

  test "GET new는 oauth signup session이 없으면 로그인으로 이동한다" do
    get :new

    assert_redirected_to new_user_session_path
  end

  test "POST create는 oauth signup session이 있으면 가입을 완료한다" do
    @request.session[:oauth_signup] = oauth_signup_session

    post :create, params: { user: { username: "oauth_user" } }

    assert_redirected_to root_path
    assert_equal "oauth_user", User.find_by!(email: "oauth@example.com").username
  end

  private

  def oauth_signup_session
    {
      "provider" => "google_oauth2",
      "uid" => "google-123",
      "email" => "oauth@example.com",
      "email_verified" => true,
      "relay_email" => false,
      "name" => "OAuth User",
      "raw_info" => { "provider" => "google_oauth2" }
    }
  end
end
