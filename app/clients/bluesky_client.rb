# frozen_string_literal: true

# rbs_inline: enabled

class BlueskyClient < ApplicationClient
  attr_reader :client

  def initialize
    super
    atproto_credentials = {
      host: 'bsky.social',
      identifier: ENV['BLUESKY_HANDLE'],
      password: ENV['BLUESKY_APP_PASSWORD']
    }
    @client = ATProto::Client.new(**atproto_credentials)
  end

  #: (String text, ?langs: Array[String]) -> untyped
  def post(text, langs: ['ko', 'en'])
    response = client.create_post(
      text: text,
      langs: langs
    )
    Rails.logger.debug "Bluesky post response: #{response.inspect}"
    response
  rescue ATProto::RequestError => e
    Rails.logger.error "Bluesky API error: #{e.message}"
    handle_atproto_error(e)
  rescue StandardError => e
    Rails.logger.error "Bluesky client error: #{e.message}"
    raise Error, e.message
  end

  private

  #: (ATProto::RequestError error) -> void
  def handle_atproto_error(error)
    case error.response&.status
    when 401
      raise Unauthorized, error.message
    when 403
      raise Forbidden, error.message
    when 404
      raise NotFound, error.message
    when 429
      raise RateLimit, error.message
    when 500..599
      raise InternalError, error.message
    else
      raise Error, error.message
    end
  end
end