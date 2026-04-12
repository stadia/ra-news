# frozen_string_literal: true
# rbs_inline: enabled

class HackerNews < ApplicationClient
  def initialize #: HackerNews
    # Initialize with the base URI for Hacker News API
    super(base_uri: "https://hacker-news.firebaseio.com/v0")
  end

  def top_stories
    get("/topstories.json")&.body
  end

  def new_stories
    get("/newstories.json")&.body
  end

  def best_stories
    get("/beststories.json")&.body
  end

  def item(id)
    get("/item/#{id}.json")&.body
  end
end
