# frozen_string_literal: true

require "test_helper"

class OauthAccounts::UsernameSuggesterTest < ActiveSupport::TestCase
  test "name 기반 username을 제안한다" do
    assert_equal "john_doe", OauthAccounts::UsernameSuggester.suggest_username(name: "John Doe", email: "john@example.com")
  end

  test "허용 문자만 남긴다" do
    assert_equal "johndoe", OauthAccounts::UsernameSuggester.sanitize('John!@#$Doe')
  end

  test "중복이면 suffix를 붙인다" do
    User.create!(email: "john-doe@example.com", username: "john_doe", name: "John Doe", password: "password123", confirmed_at: Time.current)

    assert_equal "john_doe_1", OauthAccounts::UsernameSuggester.suggest_username(name: "John Doe", email: "other@example.com")
  end

  test "너무 짧으면 fallback을 보정한다" do
    assert_equal "user", OauthAccounts::UsernameSuggester.suggest_username(name: "!", email: nil)
  end
end
