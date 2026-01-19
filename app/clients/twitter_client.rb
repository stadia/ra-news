# frozen_string_literal: true

# rbs_inline: enabled

class TwitterClient
  attr_reader :client

  def initialize
    oauth_config = Preference.get_object("xcom_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: xcom_oauth" if oauth_config.blank?

    oauth_client = OauthClientService.call(oauth_config)
    token = check_token(oauth_client, oauth_config)
    @client = Faraday.new(url: "https://api.x.com/2/") do |faraday|
      faraday.headers["Authorization"] = "Bearer #{token.token}"
      faraday.response :logger, nil, { bodies: true, log_level: :info }
      faraday.request :json
      faraday.response :json
    end
  end

  def post(text)
    response = client.post("tweets", { text: text }.to_json)
    response
  end

  def delete(tweet_id)
    response = client.delete("tweets/#{tweet_id}")
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

    if token.expired?
      token = token.refresh!
      config.update(access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: token.expires_at
      )
    end

    token
  end
end
