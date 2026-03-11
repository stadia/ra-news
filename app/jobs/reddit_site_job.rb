# frozen_string_literal: true

# rbs_inline: enabled

class RedditSiteJob < ApplicationJob
  # Reddit 내부 도메인 패턴 (이 도메인들은 외부 링크로 취급하지 않음)
  REDDIT_HOSTS = %w[
    reddit.com
    www.reddit.com
    old.reddit.com
    new.reddit.com
    redd.it
    v.redd.it
    i.redd.it
    preview.redd.it
    external-preview.redd.it
    rubygems.org
  ].freeze

  def perform
    site = Site.reddit.first
    return if site.nil?

    client = site.init_client
    feed = client.feed

    feed.items.each do |item|
      process_item(item, site)
    end

    site.update(last_checked_at: Time.zone.now)
  end

  private

  #: (RSS::Atom::Feed::Entry item, Site site) -> void
  def process_item(item, site)
    # 이미 처리된 아이템인지 확인 (origin_url 기준)
    item_url = item.link&.href
    return if item_url.blank? || Article.exists?(origin_url: item_url)

    # 본문에서 외부 링크 추출
    external_links = extract_external_links_from_content(item)

    external_links.each do |url|
      next if Article.exists?(origin_url: url)
      next if Article.should_ignore_url?(url)

      begin
        parsed_url = URI.parse(url)
        next if parsed_url.path.nil? || parsed_url.path.size < 2
      rescue URI::InvalidURIError
        next
      end

      Article.create!(
        url: url,
        origin_url: url,
        site: site,
        user: User.first_bot
      )
      sleep 1
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Failed to create article for #{url}: #{e.message}"
    end
  end

  #: (RSS::Atom::Feed::Entry item) -> Array[String]
  def extract_external_links_from_content(item)
    content = item.content&.content
    return [] if content.blank?

    doc = Nokogiri::HTML5.fragment(content)
    links = doc.css("a").map { |a| a["href"] }.compact.uniq

    links.filter do |url|
      external_link?(url)
    end
  end

  #: (String url) -> bool
  def external_link?(url)
    return false if url.blank?

    begin
      uri = URI.parse(url)
      host = uri.host&.downcase
      return false if host.blank?

      # Reddit 내부 도메인이 아닌 경우만 외부 링크로 판단
      REDDIT_HOSTS.none? { |reddit_host| host == reddit_host || host.end_with?(".#{reddit_host}") }
    rescue URI::InvalidURIError
      false
    end
  end
end
