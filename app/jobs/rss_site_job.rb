# frozen_string_literal: true

# rbs_inline: enabled

class RssSiteJob < ApplicationJob
  def self.enqueue_all
    RssSiteJob.perform_later(Site.rss.order("id ASC").pluck(:id))
  end

  # Performs the job for a given site ID.
  #: (ids Array[int] | int) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)
    feed = fetch_feed(site)
    return unless feed

    create_articles_from_feed(feed, site)

    site.update!(last_checked_at: Time.zone.now)
    RssSiteJob.perform_later(ids) unless ids.empty?
  end

  private

  def create_articles_from_feed(feed, site)
    new_articles = new_articles_from_feed(feed, site)
    new_articles.each do |article_attrs|
      create_article(article_attrs.merge(site: site))
    end
  end

  def create_article(attributes)
    # Double check existence to prevent race conditions
    return if Article.exists?(origin_url: attributes[:origin_url])

    Article.create!(attributes)
    logger.info "Created article for #{attributes[:url]}"
    sleep 1
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Failed to create article for #{attributes[:url]}: #{e.message}"
  end

  # Fetches and parses the RSS feed for a site.
  #: (site Site) -> RSS::Rss || RSS::Atom::Feed
  def fetch_feed(site)
    site.init_client&.feed(site.path)
  rescue StandardError => e
    logger.error "RSS parsing error for site #{site.id}: #{e.message}"
    nil
  end

  # Extracts new article attributes from the feed, ready for creation.
  def new_articles_from_feed(feed, site)
    attributes = feed_items(feed).map { |item| extract_item_attributes(item) }.compact

    if site.last_checked_at
      attributes.reject! { |attr| attr[:published_at] < site.last_checked_at }
    end
    return [] if attributes.empty?

    existing_urls = Article.where(origin_url: attributes.pluck(:origin_url)).pluck(:origin_url)
    attributes.reject! { |attr| existing_urls.include?(attr[:origin_url]) }
    attributes
  end

  # Returns the items from an RSS or Atom feed.
  def feed_items(feed)
    case feed
    when RSS::Rss
      feed.items
    when RSS::Atom::Feed
      feed.entries
    else
      []
    end
  end

  # Extracts attributes from a feed item.
  def extract_item_attributes(item)
    attrs = case item
    when RSS::Atom::Feed::Entry
              {
                title: item.title&.content,
                url: item.link&.href,
                origin_url: item.link&.href,
                published_at: item.published&.content || item.updated&.content || Time.zone.now
              }
    when RSS::Rss::Channel::Item
              {
                title: item.title,
                url: item.link,
                origin_url: item.link,
                published_at: item.pubDate || Time.zone.now
              }
    end

    return nil if attrs.blank? || attrs[:url].blank?

    attrs
  end
end
