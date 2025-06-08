# frozen_string_literal: true

# rbs_inline: enabled

class HackerNewsSiteJob < ApplicationJob
  def perform
    # Fetch top stories from Hacker News
    site = Site.find_by(client: "HackerNews")
    client = HackerNews.new
    top_story_ids = client.new_stories

    tags = Tag.where(is_confirmed: true, taggings_count: 4...).map(&:name)

    # Process each story ID
    top_story_ids.each do |id|
      item = client.item(id)

      next if item.nil? || item["type"] != "story" || item["url"].blank?

      url = item["url"]
      parsed_url = URI.parse(url)
      next if parsed_url.path.nil? || parsed_url.path.size < 2 || Article::IGNORE_HOSTS.any? { |pattern| parsed_url.host&.match?(/#{pattern}/i) }

      break if site.last_checked_at > Time.at(item["time"])

      # Check if title or text contains any of the tags
      title_text = "#{item['title']} #{item['text']}".downcase
      has_matching_tag = tags.any? { |tag| title_text.include?(tag.downcase) }
      # Skip if no matching tags found
      next unless has_matching_tag

      logger.debug url

      logger.debug item["title"]

      logger.debug item["text"]

      # Skip if the item is not valid or already exists
      next if Article.exists?(origin_url: item["url"])

      # # Create a new article with the fetched data
      Article.create(
        title: item["title"],
        url: item["url"],
        origin_url: item["url"],
        published_at: Time.at(item["time"]),
        site: site
      )
    end
    site.update(last_checked_at: Time.zone.now)
  end
end
