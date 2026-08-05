# typed: true
# frozen_string_literal: true

require "test_helper"

class Configs::GithubOauthTest < ActiveSupport::TestCase
  test "Preference에 값이 있으면 client_id를 반환한다" do
    Preference.create!(name: "github_oauth", value: { "client_id" => "pref-client-id", "client_secret" => "pref-secret" })

    assert_equal "pref-client-id", Configs::GithubOauth.client_id
    assert_equal "pref-secret", Configs::GithubOauth.client_secret
  end

  test "Preference에 값이 없으면 ENV에서 읽는다" do
    ClimateControl.modify GITHUB_OAUTH_CLIENT_ID: "env-client-id", GITHUB_OAUTH_CLIENT_SECRET: "env-secret" do
      assert_equal "env-client-id", Configs::GithubOauth.client_id
      assert_equal "env-secret", Configs::GithubOauth.client_secret
    end
  end

  test "둘 다 있으면 configured?는 true" do
    Preference.create!(name: "github_oauth", value: { "client_id" => "id", "client_secret" => "secret" })

    assert_predicate Configs::GithubOauth, :configured?
  end

  test "client_id가 없으면 configured?는 false" do
    ClimateControl.modify GITHUB_OAUTH_CLIENT_ID: nil, GITHUB_OAUTH_CLIENT_SECRET: "secret" do
      Preference.create!(name: "github_oauth", value: { "client_secret" => "secret" })

      refute_predicate Configs::GithubOauth, :configured?
    end
  end

  test "client_secret가 없으면 configured?는 false" do
    ClimateControl.modify GITHUB_OAUTH_CLIENT_ID: "id", GITHUB_OAUTH_CLIENT_SECRET: nil do
      Preference.create!(name: "github_oauth", value: { "client_id" => "id" })

      refute_predicate Configs::GithubOauth, :configured?
    end
  end
end
