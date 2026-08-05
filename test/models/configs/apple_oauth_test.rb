# typed: true
# frozen_string_literal: true

require "test_helper"

class Configs::AppleOauthTest < ActiveSupport::TestCase
  test "Preference에 값이 있으면 client_id, team_id, key_id를 반환한다" do
    Preference.create!(name: "apple_oauth", value: { "client_id" => "pref-client-id", "team_id" => "pref-team", "key_id" => "pref-key", "signing_secret" => "pref-pem" })

    assert_equal "pref-client-id", Configs::AppleOauth.client_id
    assert_equal "pref-team", Configs::AppleOauth.team_id
    assert_equal "pref-key", Configs::AppleOauth.key_id
    assert_equal "pref-pem", Configs::AppleOauth.private_key
  end

  test "Preference에 값이 없으면 ENV에서 읽는다" do
    ClimateControl.modify APPLE_CLIENT_ID: "env-client-id", APPLE_TEAM_ID: "env-team", APPLE_KEY_ID: "env-key", APPLE_PRIVATE_KEY: "env-pem" do
      assert_equal "env-client-id", Configs::AppleOauth.client_id
      assert_equal "env-team", Configs::AppleOauth.team_id
      assert_equal "env-key", Configs::AppleOauth.key_id
      assert_equal "env-pem", Configs::AppleOauth.private_key
    end
  end

  test "모든 필수 값이 있으면 configured?는 true" do
    Preference.create!(name: "apple_oauth", value: { "client_id" => "id", "team_id" => "team", "key_id" => "key", "signing_secret" => "pem" })

    assert_predicate Configs::AppleOauth, :configured?
  end

  test "client_id가 없으면 configured?는 false" do
    ClimateControl.modify APPLE_CLIENT_ID: nil do
      Preference.create!(name: "apple_oauth", value: { "team_id" => "team", "key_id" => "key", "signing_secret" => "pem" })

      refute_predicate Configs::AppleOauth, :configured?
    end
  end

  test "team_id가 없으면 configured?는 false" do
    ClimateControl.modify APPLE_TEAM_ID: nil do
      Preference.create!(name: "apple_oauth", value: { "client_id" => "id", "key_id" => "key", "signing_secret" => "pem" })

      refute_predicate Configs::AppleOauth, :configured?
    end
  end

  test "key_id가 없으면 configured?는 false" do
    ClimateControl.modify APPLE_KEY_ID: nil do
      Preference.create!(name: "apple_oauth", value: { "client_id" => "id", "team_id" => "team", "signing_secret" => "pem" })

      refute_predicate Configs::AppleOauth, :configured?
    end
  end

  test "private_key가 없으면 configured?는 false" do
    ClimateControl.modify APPLE_PRIVATE_KEY: nil do
      Preference.create!(name: "apple_oauth", value: { "client_id" => "id", "team_id" => "team", "key_id" => "key" })

      refute_predicate Configs::AppleOauth, :configured?
    end
  end
end
