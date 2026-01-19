# frozen_string_literal: true

# rbs_inline: enabled

class MastodonClient
  attr_reader :client

  def initialize
    oauth_config = Preference.get_object("mastodon_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: mastodon_oauth" if oauth_config.blank?

    oauth_client = OauthClientService.call(oauth_config)
    token = check_token(oauth_client, oauth_config)
    @client = Faraday.new(url: oauth_config.site) do |faraday|
      faraday.headers["Authorization"] = "Bearer #{token.token}"
      faraday.response :logger, nil, { bodies: true, log_level: :info }
      faraday.request :json
      faraday.response :json
    end
  end

  def post(text)
    response = client.post("api/v1/statuses", { status: text }.to_json)
    response
  end

  def delete(status_id)
    response = client.delete("api/v1/statuses/#{status_id}")
    response
  end

  private

  def check_token(client, config)
    return if config.access_token.nil?

    token = OAuth2::AccessToken.from_hash(client,
      {
        access_token: config.access_token,
        refresh_token: config.refresh_token,
        expires_at: config.expires_at
      }
    )

    token
  end
end
