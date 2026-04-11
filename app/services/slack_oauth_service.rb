# frozen_string_literal: true

class SlackOauthService
  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize"

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

  private

  def client
    @client ||= Slack::Web::Client.new(
      token: nil,
      open_timeout: 3,
      timeout: 5
    )
  end
end
