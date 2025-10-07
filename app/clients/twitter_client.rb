# frozen_string_literal: true

# rbs_inline: enabled

class TwitterClient
  attr_reader :client

  def initialize
    oauth_config = Preference.get_value("xcom_oauth")
    raise ArgumentError, "OAuth 설정이 비어있습니다: xcom_oauth" if oauth_config.blank?

    x_credentials = {
      access_token: oauth_config["access_token"],
      base_url: "https://api.x.com/2/",
      bearer_token: oauth_config["access_token"]
    }
    @client = X::Client.new(**x_credentials)
  end

  def post(text)
    response = client.post("tweets", { text: text }.to_json)
    Rails.logger.debug "Twitter post response: #{response.inspect}"
    response
  end
end
