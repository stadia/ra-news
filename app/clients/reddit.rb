# frozen_string_literal: true

# rbs_inline: enabled

class Reddit < ApplicationClient
  def initialize #: Reddit
    # Initialize with the base URI for Hacker News API
    super(base_uri: "https://www.reddit.com")
  end

  def feed
    response = get("/r/ruby+rails/.rss")
    RSS::Parser.parse(response.body, false)
  end
end
