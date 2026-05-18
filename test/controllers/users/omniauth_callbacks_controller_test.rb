# frozen_string_literal: true

require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  test "google callback에서 sign in 결과면 루트로 이동한다" do
    user = users(:john)

    OauthAccounts::Callbacks.stub(:handle_callback, { type: :sign_in, user: user }) do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "google-123")

      get user_google_oauth2_omniauth_callback_path

      assert_redirected_to root_path
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "apple callback에서 signup completion 결과면 oauth signup으로 이동한다" do
    OauthAccounts::Callbacks.stub(:handle_callback, { type: :complete_signup, suggested_username: "new_user" }) do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:apple] = OmniAuth::AuthHash.new(provider: "apple", uid: "apple-123")

      get user_apple_omniauth_callback_path

      assert_redirected_to new_user_oauth_registration_path
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:apple] = nil
  end
end
