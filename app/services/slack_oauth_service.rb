# frozen_string_literal: true

class SlackOauthService
  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize"
  TOKEN_URL = "https://slack.com/api/oauth.v2.access"

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
    response = connection.post do |request|
      request.url TOKEN_URL
      request.body = {
        client_id: SlackConfig.client_id,
        client_secret: SlackConfig.client_secret,
        code:,
        redirect_uri:
      }
    end

    body = response.body
    raise SlackClient::ApiError, body["error"] unless body["ok"]

    body
  end

  private

  def connection
    Faraday.new do |faraday|
      faraday.request :url_encoded
      faraday.response :json
    end
  end
end
