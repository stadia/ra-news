# frozen_string_literal: true
# rbs_inline: enabled

class Reddit < ApplicationClient
  def initialize #: Reddit
    super(url: "https://www.reddit.com")
  end

  def feed
    response = get("/r/ruby+rails/.rss")
    RSS::Parser.parse(response.body, false)
  end
end