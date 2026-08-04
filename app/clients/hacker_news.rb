# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module HackerNews
  module_function

  BASE_URL = "https://hacker-news.firebaseio.com/v0"

  def top_stories
    fetch_json("#{BASE_URL}/topstories.json")
  end

  def new_stories
    fetch_json("#{BASE_URL}/newstories.json")
  end

  def best_stories
    fetch_json("#{BASE_URL}/beststories.json")
  end

  def item(id)
    fetch_json("#{BASE_URL}/item/#{id}.json")
  end

  def fetch_json(url)
    response = Faraday.get(url) do |req|
      req.options.open_timeout = HttpTimeouts::OPEN
      req.options.timeout = HttpTimeouts::REQUEST
    end
    return nil unless response&.success?

    body = response.body
    return nil if body.blank?

    JSON.parse(body)
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.warn "HackerNews fetch failed (#{url}): #{e.class} - #{e.message}"
    nil
  end
  private_class_method :fetch_json
end
