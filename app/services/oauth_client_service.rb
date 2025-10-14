# frozen_string_literal: true

# rbs_inline: enabled

# OAuth 클라이언트 생성 및 관리 서비스
class OauthClientService < ApplicationService
  attr_reader :oauth_preference #: Preference

  OAUTH_CONFIG = {
    xcom: {
      default_site: "https://api.x.com/2/",
      authorize_url: "https://x.com/i/oauth2/authorize",
      token_url: "https://api.x.com/2/oauth2/token"
    },
    mastodon: {
      default_site: "https://ruby.social",
      authorize_url: "https://ruby.social/oauth/authorize",
      token_url: "https://ruby.social/oauth/token"
    },
    slack: {
      default_site: "https://slack.com",
      authorize_url: "https://slack.com/oauth/v2/authorize",
      token_url: "https://slack.com/api/oauth.v2.access"
    }
  }.freeze #: Hash<String, Hash<String, String>>

  #: (Preference oauth_preference) -> OauthClientService
  def initialize(oauth_preference)
    @oauth_preference = oauth_preference
  end

  # OAuth 클라이언트 생성
  def call #: OAuth2::Client
    raise ArgumentError, "OAuth 설정이 비어있습니다" if oauth_preference.blank?

    provider = extract_provider_from_preference_name
    config = OAUTH_CONFIG[provider.to_sym]
    raise ArgumentError, "지원하지 않는 provider입니다: #{provider}" if config.blank?

    client = OAuth2::Client.new(
      oauth_preference.client_id,
      oauth_preference.client_secret,
      site: oauth_preference.site || config[:default_site],
      authorize_url: config[:authorize_url],
      token_url: config[:token_url]
    )

    client
  end

  private

  #: () -> String
  def extract_provider_from_preference_name
    # "xcom_oauth" -> "xcom", "mastodon_oauth" -> "mastodon"
    oauth_preference.name.gsub(/_oauth$/, "")
  end
end
