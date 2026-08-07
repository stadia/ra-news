# frozen_string_literal: true

require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  test "google callback에서 sign in 결과면 루트로 이동한다" do
    Configs::GoogleOauth.stub(:configured?, true) do
      user = users(:john)

      OauthAccounts::Callbacks.stub(:handle_callback, OauthAccounts::Callbacks::SignIn.new(user:)) do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "google-123")

        get user_google_oauth2_omniauth_callback_path

        assert_redirected_to root_path
      end
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "apple callback에서 signup completion 결과면 oauth signup으로 이동한다" do
    Configs::AppleOauth.stub(:configured?, true) do
      OauthAccounts::Callbacks.stub(:handle_callback, OauthAccounts::Callbacks::CompleteSignup.new(suggested_username: "new_user")) do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:apple] = OmniAuth::AuthHash.new(provider: "apple", uid: "apple-123")

        get user_apple_omniauth_callback_path

        assert_redirected_to new_user_oauth_registration_path
      end
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:apple] = nil
  end

  test "github callback에서 sign in 결과면 루트로 이동한다" do
    Configs::GithubOauth.stub(:configured?, true) do
      user = users(:john)

      OauthAccounts::Callbacks.stub(:handle_callback, OauthAccounts::Callbacks::SignIn.new(user:)) do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(provider: "github", uid: "github-123")

        get user_github_omniauth_callback_path

        assert_redirected_to root_path
      end
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "google oauth가 설정되지 않았으면 로그인 페이지로 리다이렉트한다" do
    Configs::GoogleOauth.stub(:configured?, false) do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "google-123")

      get user_google_oauth2_omniauth_callback_path

      assert_redirected_to new_user_session_path
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "apple oauth가 설정되지 않았으면 로그인 페이지로 리다이렉트한다" do
    Configs::AppleOauth.stub(:configured?, false) do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:apple] = OmniAuth::AuthHash.new(provider: "apple", uid: "apple-123")

      get user_apple_omniauth_callback_path

      assert_redirected_to new_user_session_path
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:apple] = nil
  end

  test "github oauth가 설정되지 않았으면 로그인 페이지로 리다이렉트한다" do
    Configs::GithubOauth.stub(:configured?, false) do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(provider: "github", uid: "github-123")

      get user_github_omniauth_callback_path

      assert_redirected_to new_user_session_path
    end
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end
end
