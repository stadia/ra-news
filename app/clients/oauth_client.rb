# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module OauthClient
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
    }
  }.freeze #: Hash[Symbol, Hash[Symbol, String]]

  module_function

  #: (Preference oauth_preference) -> OAuth2::Client
  def build(oauth_preference)
    raise ArgumentError, "OAuth 설정이 비어있습니다" if oauth_preference.blank?
    raise ArgumentError, "OAuth 설정 이름이 비어있습니다" if oauth_preference.name.blank?

    provider = extract_provider_from_preference_name(oauth_preference.name)
    config = OAUTH_CONFIG.fetch(provider.to_sym) do
      raise ArgumentError, "지원하지 않는 provider입니다: #{provider}"
    end
    raise ArgumentError, "지원하지 않는 provider입니다: #{provider}" if config.empty?

    OAuth2::Client.new(
      oauth_preference.client_id,
      oauth_preference.client_secret,
      site: oauth_preference.site || config[:default_site],
      authorize_url: config[:authorize_url],
      token_url: config[:token_url],
      connection_opts: { request: { open_timeout: HttpTimeouts::OPEN, timeout: HttpTimeouts::REQUEST } }
    )
  end

  #: (String name) -> String
  def extract_provider_from_preference_name(name)
    name.gsub(/_oauth$/, "")
  end

  private_class_method :extract_provider_from_preference_name
end
