# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class SlackClient
  class ApiError < StandardError; end

  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize" #: String

  # ── Instance methods ────────────────────────────────────

  #: (SlackChannel channel) -> void
  def initialize(channel)
    @channel = channel
  end

  #: (text: String, blocks: Array[untyped]) -> Hash[String, String]
  def post_message(text:, blocks:)
    response = webhook_client.post do |request|
      request.body = {
        text:,
        blocks:
      }
    end

    unless response.success?
      raise ApiError, "Slack webhook 전송에 실패했습니다. HTTP #{response.status}"
    end

    {}
  rescue Faraday::Error => e
    raise_api_error(e)
  end

  private

  attr_reader :channel #: SlackChannel

  # @rbs @webhook_client: Faraday::Connection?

  #: () -> Faraday::Connection
  def webhook_client
    @webhook_client ||= Faraday.new(url: channel.webhook_url) do |faraday|
      faraday.request :json
      faraday.response :raise_error
      faraday.adapter Faraday.default_adapter
    end
  end

  #: (Exception error) -> bot
  def raise_api_error(error)
    raise ApiError, "#{error.class}: #{error.message}"
  end

  class << self
    # ── OAuth (class methods) ──────────────────────────────

    #: (redirect_uri: String, state: String) -> String
    def authorize_url(redirect_uri:, state:)
      query = {
        client_id: Configs::Slack.client_id,
        scope: Configs::Slack.install_scope,
        redirect_uri:,
        state:
      }.to_query

      "#{AUTHORIZE_URL}?#{query}"
    end

    #: (String code, redirect_uri: String) -> ActiveSupport::HashWithIndifferentAccess
    def exchange_code(code, redirect_uri:)
      response = oauth_client.oauth_v2_access(
        client_id: Configs::Slack.client_id,
        client_secret: Configs::Slack.client_secret,
        code:,
        redirect_uri:
      )

      response.to_h.with_indifferent_access
    rescue Slack::Web::Api::Errors::SlackError => e
      raise ApiError, e.message
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end

    #: (?String? token) -> Slack::Web::Client
    def oauth_client(token = nil)
      Slack::Web::Client.new(
        token:,
        open_timeout: 3,
        timeout: 5
      )
    end
  end
end
