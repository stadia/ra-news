# frozen_string_literal: true
# rbs_inline: enabled

module SlackOauth
  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize"
  module_function

  def authorize_url(redirect_uri:, state:)
    query = {
      client_id: SlackConfig.client_id,
      scope: SlackConfig.install_scope,
      redirect_uri:,
      state:
    }.to_query

    "#{AUTHORIZE_URL}?#{query}"
  end

  def exchange_code(code, redirect_uri:)
    response = client.oauth_v2_access(
      client_id: SlackConfig.client_id,
      client_secret: SlackConfig.client_secret,
      code:,
      redirect_uri:
    )

    response.to_h.with_indifferent_access
  rescue Slack::Web::Api::Errors::SlackError => e
    raise SlackClient::ApiError, e.message
  rescue Faraday::Error => e
    raise SlackClient::ApiError, "oauth_exchange_failed: #{e.class}"
  end

  def client
    @client ||= Slack::Web::Client.new(
      token: nil,
      open_timeout: 3,
      timeout: 5
    )
  end
  private_class_method :client
end
