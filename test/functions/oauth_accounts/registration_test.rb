# frozen_string_literal: true

require "test_helper"

class OauthAccounts::RegistrationTest < ActiveSupport::TestCase
  test "oauth signup session으로 user와 oauth account를 생성한다" do
    result = OauthAccounts::Registration.register_user(
      session_data: session_data,
      username: "oauth_user",
      locale: "ko",
      signup_host: "ruby-news.kr"
    )

    assert result[:success]

    user = result[:user]

    assert_equal "oauth@example.com", user.email
    assert_equal "oauth_user", user.username
    assert_equal "ko", user.locale
    assert_equal "ruby-news.kr", user.signup_host
    assert_not_nil user.confirmed_at

    account = OauthAccount.find_by!(provider: "google_oauth2", uid: "google-123")

    assert_equal user, account.user
    assert account.email_verified
  end

  test "username이 유효하지 않으면 실패를 반환한다" do
    result = OauthAccounts::Registration.register_user(
      session_data: session_data,
      username: "한글",
      locale: "ko",
      signup_host: "ruby-news.kr"
    )

    refute result[:success]
    assert_predicate result[:user].errors[:username], :any?
  end

  private

  def session_data
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
