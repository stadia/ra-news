# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

# OauthClientService 테스트
# Preference 모델은 value 컬럼에 JSON 데이터를 저장하고 동적 accessor를 사용합니다.
class OauthClientServiceTest < ActiveSupport::TestCase
  # 테스트용 Preference mock 객체 생성 헬퍼
  def create_mock_preference(name:, client_id:, client_secret:, site: nil)
    mock = Minitest::Mock.new
    mock.expect(:blank?, false)
    mock.expect(:name, name)
    mock.expect(:client_id, client_id)
    mock.expect(:client_secret, client_secret)
    mock.expect(:site, site)
    mock.expect(:name, name) # extract_provider_from_preference_name 호출용
    mock
  end

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

    client = OauthClientService.call(preference)

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

    client = OauthClientService.call(preference)

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

    client = OauthClientService.call(preference)

    assert_equal "https://custom-mastodon.instance", client.site
  end

  test "Slack OAuth 클라이언트를 올바르게 생성한다" do
    preference = MockPreference.new(
      name: "slack_oauth",
      client_id: "slack_client_id",
      client_secret: "slack_client_secret",
      site: nil
    )

    client = OauthClientService.call(preference)

    assert_instance_of OAuth2::Client, client
    assert_equal "slack_client_id", client.id
    assert_equal "https://slack.com", client.site
    assert_equal "https://slack.com/oauth/v2/authorize", client.options[:authorize_url]
    assert_equal "https://slack.com/api/oauth.v2.access", client.options[:token_url]
  end

  test "OAuth 설정이 비어있으면 ArgumentError를 발생시킨다" do
    error = assert_raises(ArgumentError) do
      OauthClientService.call(nil)
    end

    assert_equal "OAuth 설정이 비어있습니다", error.message
  end

  test "지원하지 않는 provider면 ArgumentError를 발생시킨다" do
    preference = MockPreference.new(
      name: "unsupported_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )

    error = assert_raises(ArgumentError) do
      OauthClientService.call(preference)
    end

    assert_match(/지원하지 않는 provider입니다/, error.message)
  end

  test "인스턴스를 직접 생성하고 call을 호출할 수 있다" do
    preference = MockPreference.new(
      name: "xcom_oauth",
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      site: nil
    )

    service = OauthClientService.new(preference)
    client = service.call

    assert_instance_of OAuth2::Client, client
    assert_equal "test_client_id", client.id
  end

  test "provider 이름을 preference name에서 올바르게 추출한다" do
    # xcom_oauth -> xcom
    xcom_preference = MockPreference.new(
      name: "xcom_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )
    client = OauthClientService.call(xcom_preference)
    assert_equal "https://api.x.com/2/", client.site

    # mastodon_oauth -> mastodon (커스텀 site 사용)
    mastodon_preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: "https://ruby.social"
    )
    client = OauthClientService.call(mastodon_preference)
    assert_equal "https://ruby.social", client.site
  end

  test "site가 nil이면 기본 site를 사용한다" do
    preference = MockPreference.new(
      name: "mastodon_oauth",
      client_id: "test_id",
      client_secret: "test_secret",
      site: nil
    )

    client = OauthClientService.call(preference)

    # Mastodon 기본 site
    assert_equal "https://ruby.social", client.site
  end
end
