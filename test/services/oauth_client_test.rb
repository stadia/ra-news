# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

# OauthClient 테스트
# Preference 모델은 value 컬럼에 JSON 데이터를 저장하고 동적 accessor를 사용합니다.
class OauthClientTest < ActiveSupport::TestCase
  # 테스트용 Struct 기반 Preference 대체 객체
  MockPreference = Struct.new(:name, :client_id, :client_secret, :site, keyword_init: true) do
    def blank?
      false
    end
  end

  test "X.com OAuth 클라이언트를 올바르게 생성한다" do
    preference = MockPreference.new(
      name: "xcom_oauth",
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      site: nil
    )

    client = OauthClient.build(preference)

    assert_instance_of OAuth2::Client, client
    assert_equal "test_client_id", client.id
    assert_equal "test_client_secret", client.secret
    assert_equal "https://api.x.com/2/", client.site
    assert_equal "https://x.com/i/oauth2/authorize", client.options[:authorize_url]
    assert_equal "https://api.x.com/2/oauth2/token", client.options[:token_url]
  end

  test "Mastodon OAuth 클라이언트를 올바르게 생성한다" do
    preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "mastodon_client_id",
      client_secret: "mastodon_client_secret",
      site: "https://ruby.social"
    )

    client = OauthClient.build(preference)

    assert_instance_of OAuth2::Client, client
    assert_equal "mastodon_client_id", client.id
    assert_equal "mastodon_client_secret", client.secret
    assert_equal "https://ruby.social", client.site
    assert_equal "https://ruby.social/oauth/authorize", client.options[:authorize_url]
    assert_equal "https://ruby.social/oauth/token", client.options[:token_url]
  end

  test "커스텀 site가 지정되면 기본값 대신 사용한다" do
    preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "custom_client_id",
      client_secret: "custom_client_secret",
      site: "https://custom-mastodon.instance"
    )

    client = OauthClient.build(preference)

    assert_equal "https://custom-mastodon.instance", client.site
  end

  test "OAuth 설정이 비어있으면 ArgumentError를 발생시킨다" do
    error = assert_raises(ArgumentError) do
      OauthClient.build(nil)
    end

    assert_equal "OAuth 설정이 비어있습니다", error.message
  end

  test "preference 이름이 비어있으면 ArgumentError를 발생시킨다" do
    preference = MockPreference.new(
      name: nil,
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )

    error = assert_raises(ArgumentError) do
      OauthClient.build(preference)
    end

    assert_equal "OAuth 설정 이름이 비어있습니다", error.message
  end

  test "지원하지 않는 provider면 ArgumentError를 발생시킨다" do
    preference = MockPreference.new(
      name: "unsupported_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )

    error = assert_raises(ArgumentError) do
      OauthClient.build(preference)
    end

    assert_match(/지원하지 않는 provider입니다/, error.message)
  end

  test "provider 이름을 preference name에서 올바르게 추출한다" do
    # xcom_oauth -> xcom
    xcom_preference = MockPreference.new(
      name: "xcom_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )
    client = OauthClient.build(xcom_preference)

    assert_equal "https://api.x.com/2/", client.site

    # mastodon_oauth -> mastodon (커스텀 site 사용)
    mastodon_preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: "https://ruby.social"
    )
    client = OauthClient.build(mastodon_preference)

    assert_equal "https://ruby.social", client.site
  end

  test "site가 nil이면 기본 site를 사용한다" do
    preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )

    client = OauthClient.build(preference)

    # Mastodon 기본 site
    assert_equal "https://ruby.social", client.site
  end
end
