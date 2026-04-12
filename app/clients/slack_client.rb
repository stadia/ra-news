# frozen_string_literal: true
# rbs_inline: enabled

class SlackClient
  class ApiError < StandardError; end

  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize"

  # ── Instance methods ────────────────────────────────────

  def initialize(workspace)
    @workspace = workspace
  end

  def list_channels
    channels = []

    client.conversations_list(
      exclude_archived: true,
      types: "public_channel,private_channel",
      limit: 200
    ) do |response|
      channels.concat(response.channels.map { |ch| { "id" => ch.id, "name" => ch.name } })
    end

    channels
  rescue Slack::Web::Api::Errors::SlackError => e
    raise ApiError, e.message
  rescue Faraday::Error => e
    raise_api_error(e)
  end

  def post_message(channel:, text:, blocks:)
    response = client.chat_postMessage(channel:, text:, blocks:)
    { "ts" => response.ts }
  rescue Slack::Web::Api::Errors::SlackError => e
    raise ApiError, e.message
  rescue Faraday::Error => e
    raise_api_error(e)
  end

  private

  attr_reader :workspace

  def client
    @client ||= SlackClient.oauth_client(workspace.bot_access_token)
  end

  def raise_api_error(error)
    raise ApiError, "#{error.class}: #{error.message}"
  end

  class << self
    # ── OAuth (class methods) ──────────────────────────────

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
      response = oauth_client.oauth_v2_access(
        client_id: SlackConfig.client_id,
        client_secret: SlackConfig.client_secret,
        code:,
        redirect_uri:
      )

      response.to_h.with_indifferent_access
    rescue Slack::Web::Api::Errors::SlackError => e
      raise ApiError, e.message
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end

    private

    def oauth_client(token = nil)
      Slack::Web::Client.new(
        token:,
        open_timeout: 3,
        timeout: 5
      )
    end
  end
end
