# frozen_string_literal: true

# rbs_inline: enabled

require "rss"

class RssClient < ApplicationClient
  #: (String path) -> RSS::Rss?
  def feed(path)
    response = get(path)
    if response.status.between?(300, 399) && response.headers["location"]
      response = get(response.headers["location"])
    end

    begin
      RSS::Parser.parse(response.body, false)
    rescue RSS::Error => e
      logger.error "RSS parsing error for path #{path}: #{e.message}"
      nil
    rescue StandardError => e
      logger.error "Unexpected error parsing RSS from #{path}: #{e.message}"
      nil
    end
  end
end
