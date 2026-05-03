# frozen_string_literal: true
# rbs_inline: enabled

require "rss"

class Reddit
  BASE_URL = "https://www.reddit.com"

  def feed
    response = Faraday.get("#{BASE_URL}/r/ruby+rails/.rss")
    RSS::Parser.parse(response.body, false)
  end
end