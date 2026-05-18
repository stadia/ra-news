# frozen_string_literal: true

require "test_helper"

class OauthAccounts::UserMatcherTest < ActiveSupport::TestCase
  test "existing oauth account가 있으면 해당 사용자를 반환한다" do
    user = users(:john)
    OauthAccount.create!(user:, provider: "google_oauth2", uid: "google-123")

    assert_equal user, OauthAccounts::UserMatcher.match_user(provider: "google_oauth2", uid: "google-123", email: "other@example.com", email_verified: true, relay_email: false)
  end

  test "verified email이면 기존 user를 자동 연결한다" do
    user = users(:john)

    assert_equal user, OauthAccounts::UserMatcher.match_user(provider: "google_oauth2", uid: "google-123", email: user.email, email_verified: true, relay_email: false)
  end

  test "verified email이 아니면 기존 user를 자동 연결하지 않는다" do
    assert_nil OauthAccounts::UserMatcher.match_user(provider: "google_oauth2", uid: "google-123", email: users(:john).email, email_verified: false, relay_email: false)
  end

  test "apple relay email이면 기존 user를 자동 연결하지 않는다" do
    assert_nil OauthAccounts::UserMatcher.match_user(provider: "apple", uid: "apple-123", email: users(:john).email, email_verified: true, relay_email: true)
  end
end
