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
    RSS::Parser.parse(response.body, false)
  end
end
