# frozen_string_literal: true
# rbs_inline: enabled

require "rss"

class RssClient
  attr_reader :url

  #: (String url) -> void
  def initialize(url)
    @url = url
  end

  #: -> RSS::Rss | RSS::Atom::Feed | nil
  def feed
    response = Faraday.get(@url)
    if response.status.between?(300, 399) && response.headers["location"]
      response = Faraday.get(response.headers["location"])
    end
    RSS::Parser.parse(response.body, false)
  end
end