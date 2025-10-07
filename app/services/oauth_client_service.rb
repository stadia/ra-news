# frozen_string_literal: true

# rbs_inline: enabled

# OAuth 클라이언트 생성 및 관리 서비스
class OauthClientService < ApplicationService
  attr_reader :provider #: String

  #: (String provider) -> OauthClientService
  def initialize(provider)
    @provider = provider
  end

  # OAuth 클라이언트 생성
  def call #: OAuth2::Client
    oauth_config = Preference.get_value("#{provider}_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: #{provider}_oauth" if oauth_config.blank?

    OAuth2::Client.new(
      oauth_config["client_id"],
      oauth_config["client_secret"],
      site: oauth_config["site"] || default_site,
      authorize_url: authorize_url,
      token_url: token_url
    )
  end

  # OAuth 기본 사이트 URL
  #: (String provider) -> String
  def default_site
    case provider
    when "xcom"
      "https://api.x.com"
    when "google"
      "https://accounts.google.com"
    else
      "https://#{provider}.com"
    end
  end

  # OAuth 인증 URL
  #: (String provider) -> String
  def authorize_url
    case provider
    when "xcom"
      "https://x.com/i/oauth2/authorize"
    when "google"
      "https://accounts.google.com/o/oauth2/v2/auth"
    else
      "https://#{provider}.com/oauth2/authorize"
    end
  end

  # OAuth 토큰 URL
  #: (String provider) -> String
  def token_url
    case provider
    when "xcom"
      "https://api.x.com/2/oauth2/token"
    when "google"
      "https://oauth2.googleapis.com/token"
    else
      "https://#{provider}.com/oauth2/token"
    end
  end
end
