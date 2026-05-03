# frozen_string_literal: true
# rbs_inline: enabled

require "rss"

module RssClient
  module_function

  #: (String url) -> RSS::Rss | RSS::Atom::Feed | nil
  def feed(url)
    response = Faraday.get(url)
    if response.status.between?(300, 399) && response.headers["location"]
      response = Faraday.get(response.headers["location"])
    end
    RSS::Parser.parse(response.body, false)
  end
end
