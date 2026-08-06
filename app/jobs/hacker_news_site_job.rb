# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class HackerNewsSiteJob < ApplicationJob
  def perform
    # Fetch top stories from Hacker News
    site = Site.hacker_news.first
    return if site.nil?

    # 수집 중 발행되는 스토리를 놓치지 않도록 조회 전 시각을 커서로 사용한다.
    run_started_at = Time.zone.now
    top_story_ids = HackerNews.new_stories
    return if top_story_ids.blank?

    tag_terms = %w[ruby rails]
    tag_terms += Tag.where(is_confirmed: true, taggings_count: 2..).order(taggings_count: :desc).limit(50).pluck(:name)
                   .map { |n| Regexp.escape(n.downcase.gsub(/[-_]/, " ")) }
    tag_pattern = Regexp.new("\\b(#{tag_terms.join("|")})\\b")

    # Process each story ID
    last_checked = site.last_checked_at
    top_story_ids.each do |id|
      break unless process_story(id, site, tag_pattern, last_checked)
    end
    site.update(last_checked_at: run_started_at)
  end

  private

  # Processes a single story. Returns false when the story is older than the
  # last check (caller should stop), true otherwise.
  def process_story(id, site, tag_pattern, last_checked)
    item = HackerNews.item(id)

    return true if item.nil? || item["type"] != "story" || item["url"].blank?

    url = item["url"]
    begin
      parsed_url = URI.parse(url)
    rescue URI::InvalidURIError => e
      logger.error "Failed to parse URL #{url}: #{e.message}"
      return true
    end

    path = parsed_url.path
    return true if path.nil? || path.size < 2 || Articles::Utils.should_ignore_url?(parsed_url.to_s)

    return false if last_checked && last_checked > Time.at(item["time"])

    title_text = "#{item["title"]} #{item["text"]}".downcase
    has_matching_tag = tag_pattern.match?(title_text)
    # Skip if no matching tags found
    return true unless has_matching_tag

    logger.debug url

    logger.debug item["title"]

    logger.debug item["text"]

    # Create a new article with the fetched data (skips if it already exists)
    article = Article.create_with(
      title: item["title"],
      url: item["url"],
      published_at: Time.at(item["time"]),
      site: site,
      user: User.find_by(username: "bot")
    ).find_or_create_by(origin_url: item["url"])
    sleep 1 if article.previously_new_record?
    true
  end
end
