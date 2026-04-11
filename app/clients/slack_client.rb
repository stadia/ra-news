# frozen_string_literal: true

class SlackClient
  class ApiError < StandardError; end

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
  end

  def post_message(channel:, text:, blocks:)
    response = client.chat_postMessage(channel:, text:, blocks:)
    { "ts" => response.ts }
  rescue Slack::Web::Api::Errors::SlackError => e
    raise ApiError, e.message
  end

  private

  attr_reader :workspace

  def client
    @client ||= Slack::Web::Client.new(
      token: workspace.bot_access_token,
      open_timeout: 3,
      timeout: 5
    )
  end
end
