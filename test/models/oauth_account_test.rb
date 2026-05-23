# frozen_string_literal: true

require "test_helper"

class OauthAccountTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
  end

  test "provider와 uid가 있으면 유효하다" do
    account = OauthAccount.new(user: @user, provider: "google_oauth2", uid: "google-123")

    assert_predicate account, :valid?
  end

  test "provider는 필수다" do
    account = OauthAccount.new(user: @user, provider: nil, uid: "google-123")

    assert_not account.valid?
    assert account.errors.of_kind?(:provider, :blank)
  end

  test "uid는 필수다" do
    account = OauthAccount.new(user: @user, provider: "google_oauth2", uid: nil)

    assert_not account.valid?
    assert account.errors.of_kind?(:uid, :blank)
  end

  test "provider와 uid 조합은 유일해야 한다" do
    OauthAccount.create!(user: @user, provider: "google_oauth2", uid: "google-123")
    account = OauthAccount.new(user: users(:jane), provider: "google_oauth2", uid: "google-123")

    assert_not account.valid?
    assert account.errors.of_kind?(:uid, :taken)
  end

  test "user는 oauth_accounts를 가진다" do
    association = User.reflect_on_association(:oauth_accounts)

    assert_equal :has_many, association.macro
  end
end
