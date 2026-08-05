# typed: true
# frozen_string_literal: true

require "test_helper"

class Configs::GoogleOauthTest < ActiveSupport::TestCase
  test "Preference에 값이 있으면 client_id를 반환한다" do
    Preference.create!(name: "google_oauth", value: { "client_id" => "pref-client-id", "client_secret" => "pref-secret" })

    assert_equal "pref-client-id", Configs::GoogleOauth.client_id
    assert_equal "pref-secret", Configs::GoogleOauth.client_secret
  end

  test "Preference에 값이 없으면 ENV에서 읽는다" do
    ClimateControl.modify GOOGLE_OAUTH_CLIENT_ID: "env-client-id", GOOGLE_OAUTH_CLIENT_SECRET: "env-secret" do
      assert_equal "env-client-id", Configs::GoogleOauth.client_id
      assert_equal "env-secret", Configs::GoogleOauth.client_secret
    end
  end

  test "Preference 값이 ENV보다 우선한다" do
    Preference.create!(name: "google_oauth", value: { "client_id" => "pref-id", "client_secret" => "pref-secret" })

    ClimateControl.modify GOOGLE_OAUTH_CLIENT_ID: "env-id", GOOGLE_OAUTH_CLIENT_SECRET: "env-secret" do
      assert_equal "pref-id", Configs::GoogleOauth.client_id
      assert_equal "pref-secret", Configs::GoogleOauth.client_secret
    end
  end

  test "둘 다 있으면 configured?는 true" do
    Preference.create!(name: "google_oauth", value: { "client_id" => "id", "client_secret" => "secret" })

    assert_predicate Configs::GoogleOauth, :configured?
  end

  test "client_id가 없으면 configured?는 false" do
    ClimateControl.modify GOOGLE_OAUTH_CLIENT_ID: nil, GOOGLE_OAUTH_CLIENT_SECRET: "secret" do
      Preference.create!(name: "google_oauth", value: { "client_secret" => "secret" })

      refute_predicate Configs::GoogleOauth, :configured?
    end
  end

  test "client_secret가 없으면 configured?는 false" do
    ClimateControl.modify GOOGLE_OAUTH_CLIENT_ID: nil, GOOGLE_OAUTH_CLIENT_SECRET: nil do
      Preference.create!(name: "google_oauth", value: { "client_id" => "id" })

      refute_predicate Configs::GoogleOauth, :configured?
    end
  end
end
