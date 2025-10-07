# frozen_string_literal: true

# rbs_inline: enabled

class TwitterClient
  attr_reader :client

  def initialize
    oauth_config = Preference.get_value("xcom_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: xcom_oauth" if oauth_config.blank?

    x_credentials = {
      api_key: ENV["X_API_KEY"],
      api_key_secret: ENV["X_API_KEY_SECRET"],
      access_token: ENV["X_ACCESS_TOKEN"],
      access_token_secret: ENV["X_ACCESS_TOKEN_SECRET"]
    }
    @client = X::Client.new(**x_credentials)
  end

  def post(text)
    response = client.post("tweets", { text: text }.to_json)
    Rails.logger.debug "Twitter post response: #{response.inspect}"
    response
  end
end
