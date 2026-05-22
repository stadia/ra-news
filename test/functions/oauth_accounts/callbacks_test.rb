# frozen_string_literal: true

require "test_helper"

class OauthAccounts::CallbacksTest < ActiveSupport::TestCase
  test "google payload를 정규화한다" do
    result = OauthAccounts::Callbacks.build_auth_result(auth: google_auth_hash(email: "john@example.com"))

    assert_equal "google_oauth2", result[:provider]
    assert_equal "google-123", result[:uid]
    assert_equal "john@example.com", result[:email]
    assert_equal "John Doe", result[:name]
    assert result[:email_verified]
    refute result[:relay_email]
  end

  test "apple relay email을 판별한다" do
    auth = {
      "provider" => "apple",
      "uid" => "apple-123",
      "info" => {
        "email" => "abc@privaterelay.appleid.com",
        "name" => "John Appleseed"
      },
      "credentials" => {
        "email_verified" => true
      }
    }

    result = OauthAccounts::Callbacks.build_auth_result(auth: auth)

    assert result[:email_verified]
    assert result[:relay_email]
  end

  test "existing oauth account면 sign_in 결과를 반환한다" do
    user = users(:john)
    OauthAccount.create!(user:, provider: "google_oauth2", uid: "google-123")
    session = {}

    result = OauthAccounts::Callbacks.handle_callback(auth: google_auth_hash(email: user.email), session: session)

    assert_equal :sign_in, result[:type]
    assert_equal user, result[:user]
    assert_nil session[:oauth_signup]
  end

  test "verified email 기존 user를 oauth account에 연결한다" do
    user = users(:john)
    session = {}

    result = OauthAccounts::Callbacks.handle_callback(auth: google_auth_hash(email: user.email), session: session)

    assert_equal :sign_in, result[:type]
    assert_equal user, result[:user]
    account = OauthAccount.find_by(provider: "google_oauth2", uid: "google-123")

    assert_equal user, account.user
  end

  test "기존 oauth account 로그인 시 빈 provider 정보로 기존 값을 덮어쓰지 않는다" do
    user = users(:john)
    OauthAccount.create!(
      user:,
      provider: "apple",
      uid: "apple-123",
      email: "first-login@example.com",
      email_verified: true,
      raw_info: {
        "provider" => "apple",
        "uid" => "apple-123",
        "info" => {
          "email" => "first-login@example.com",
          "name" => "First Login"
        }
      }
    )
    session = {}

    result = OauthAccounts::Callbacks.handle_callback(auth: apple_auth_hash(email: nil, name: nil), session: session)

    assert_equal :sign_in, result[:type]

    account = OauthAccount.find_by!(provider: "apple", uid: "apple-123")

    assert_equal "first-login@example.com", account.email
    assert_equal "First Login", account.raw_info.dig("info", "name")
  end

  test "신규 user면 signup completion 결과와 suggested username을 반환한다" do
    session = {}

    result = OauthAccounts::Callbacks.handle_callback(auth: google_auth_hash(email: "new-user@example.com", name: "New User"), session: session)

    assert_equal :complete_signup, result[:type]
    assert_equal "new_user", result[:suggested_username]
    assert_equal "new-user@example.com", session.dig(:oauth_signup, "email")
  end

  test "signup completion 세션에 raw_info를 보존한다" do
    session = {}

    OauthAccounts::Callbacks.handle_callback(
      auth: apple_auth_hash(email: "first-login@example.com", name: "First Login"),
      session: session
    )

    assert_equal "first-login@example.com", session.dig(:oauth_signup, "raw_info", "info", "email")
    assert_equal "First Login", session.dig(:oauth_signup, "raw_info", "info", "name")
  end

  private

  def google_auth_hash(email:, name: "John Doe")
    {
      "provider" => "google_oauth2",
      "uid" => "google-123",
      "info" => {
        "email" => email,
        "name" => name,
        "email_verified" => true
      }
    }
  end

  def apple_auth_hash(email:, name:)
    {
      "provider" => "apple",
      "uid" => "apple-123",
      "info" => {
        "email" => email,
        "name" => name
      },
      "credentials" => {
        "email_verified" => true
      }
    }
  end
end
