# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders sign in page without resend confirmation link" do
    get new_user_session_path

    assert_response :success
    assert_select "a[href='#{new_user_confirmation_path}']", count: 0
    assert_select "form[action='#{user_google_oauth2_omniauth_authorize_path}'] button", text: I18n.t("sessions.new.continue_with_google")
    assert_select "form[action='#{user_apple_omniauth_authorize_path}'] button", text: I18n.t("sessions.new.continue_with_apple")
  end

  test "GET new renders english oauth button labels when locale is en" do
    host! "localhost"

    get new_user_session_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }

    assert_response :success
    assert_select "form[action='#{user_google_oauth2_omniauth_authorize_path}'] button", text: "Continue with Google"
    assert_select "form[action='#{user_apple_omniauth_authorize_path}'] button", text: "Continue with Apple"
  end

  test "POST create with unconfirmed user shows resend confirmation link" do
    user = users(:john)
    user.update!(confirmed_at: nil)

    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
    follow_redirect!

    assert_response :success
    assert_equal I18n.t("devise.failure.unconfirmed"), flash[:alert]
    assert_select "a[href='#{new_user_confirmation_path}']", text: I18n.t("sessions.new.resend_confirmation")
  end

  test "GET new redirects to root for already signed in user" do
    user = users(:john)
    sign_in_as(user)

    get new_user_session_path

    assert_redirected_to root_url
  end

  test "POST create signs in user with valid credentials" do
    user = users(:john)

    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }

    assert_redirected_to root_url
  end

  test "POST create fails with invalid credentials" do
    post user_session_path, params: {
      user: { email: "wrong@example.com", password: "wrongpassword" }
    }

    assert_response :unprocessable_entity
  end

  test "JSON login returns Authorization header and refresh_token body" do
    user = users(:john)

    post user_session_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json

    assert_response :success
    assert_match(/^Bearer /, response.headers["Authorization"].to_s)

    body = JSON.parse(response.body)

    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
    assert_predicate body["refresh_token"], :present?
  end

  test "JSON login with bad password returns 401 JSON" do
    user = users(:john)

    post user_session_path,
         params: { user: { email: user.email, password: "wrong" } },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON logout revokes user refresh tokens" do
    user = users(:john)

    post user_session_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_match(/^Bearer /, token.to_s)
    assert_operator user.refresh_tokens.active.count, :>=, 1

    get destroy_user_session_path,
        headers: { "Authorization" => token },
        as: :json

    assert_response :no_content
    assert_equal 0, user.refresh_tokens.active.count
  end
end
