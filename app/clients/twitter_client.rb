# frozen_string_literal: true

# rbs_inline: enabled

class TwitterClient < ApplicationClient
  attr_reader :client

  def initialize
    @client = X::Client.new
  end

  def post(text)
    response = client.post("tweets", { text: text }.to_json)

    unless response.status.success?
      raise Error, "Twitter API error: #{response.status} - #{response.body}"
    end

    response
  end
end
