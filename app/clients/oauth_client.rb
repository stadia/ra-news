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

  def build(oauth_preference) #: (Preference oauth_preference) -> OAuth2::Client
    raise ArgumentError, "OAuth 설정이 비어있습니다" if oauth_preference.blank?
    raise ArgumentError, "OAuth 설정 이름이 비어있습니다" if oauth_preference.name.blank?

    provider = extract_provider_from_preference_name(oauth_preference.name)
    config = OAUTH_CONFIG[provider.to_sym]
    raise ArgumentError, "지원하지 않는 provider입니다: #{provider}" if config.blank?

    OAuth2::Client.new(
      oauth_preference.client_id,
      oauth_preference.client_secret,
      site: oauth_preference.site || config[:default_site],
      authorize_url: config[:authorize_url],
      token_url: config[:token_url]
    )
  end

  def extract_provider_from_preference_name(name) #: (String name) -> String
    name.gsub(/_oauth$/, "")
  end

  private_class_method :extract_provider_from_preference_name
end
