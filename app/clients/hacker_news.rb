# frozen_string_literal: true
# rbs_inline: enabled

class HackerNews
  BASE_URL = "https://hacker-news.firebaseio.com/v0"

  def top_stories
    Faraday.get("#{BASE_URL}/topstories.json")&.body
  end

  def new_stories
    Faraday.get("#{BASE_URL}/newstories.json")&.body
  end

  def best_stories
    Faraday.get("#{BASE_URL}/beststories.json")&.body
  end

  def item(id)
    Faraday.get("#{BASE_URL}/item/#{id}.json")&.body
  end
end