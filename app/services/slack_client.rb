# frozen_string_literal: true

class SlackClient
  class ApiError < StandardError; end

  def initialize(workspace)
    @workspace = workspace
  end

  def list_channels
    body = get("conversations.list", limit: 500, exclude_archived: true, types: "public_channel,private_channel")
    Array(body["channels"]).map do |channel|
      {
        "id" => channel["id"],
        "name" => channel["name"]
      }
    end
  end

  def post_message(channel:, text:, blocks:)
    post("chat.postMessage", channel:, text:, blocks:)
  end

  private

  attr_reader :workspace

  def get(path, **params)
    response = connection.get(path, params)
    parse_response(response)
  end

  def post(path, **payload)
    response = connection.post(path) do |request|
      request.body = payload
    end
    parse_response(response)
  end

  def parse_response(response)
    body = response.body
    raise ApiError, body["error"] unless body["ok"]

    body
  end

  def connection
    Faraday.new(url: "https://slack.com/api/") do |faraday|
      faraday.headers["Authorization"] = "Bearer #{workspace.bot_access_token}"
      faraday.request :json
      faraday.response :json
    end
  end
end
