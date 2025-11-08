# frozen_string_literal: true

# rbs_inline: enabled

class RssSiteJob < ApplicationJob
  include RssHelper

  def self.enqueue_all
    RssSiteJob.perform_later(Site.kept.rss.order("id ASC").pluck(:id))
  end

  # Performs the job for a given site ID.
  #: (Array[Integer] ids) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)
    feed = fetch_feed(site)
    unless feed
      RssSiteJob.perform_later(ids) unless ids.empty?
      return
    end

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

  # Extracts new article attributes from the feed, ready for creation.
  def new_articles_from_feed(feed, site)
    attributes = feed_items(feed).map { |item| extract_item_attributes(item) }.compact

    if site.last_checked_at
      attributes.reject! { |attr| attr[:published_at] < site.last_checked_at }
    end
    return [] if attributes.empty?

    logger.debug attributes
    existing_urls = Article.where(origin_url: attributes.pluck(:origin_url)).pluck(:origin_url)
    attributes.reject! { |attr| existing_urls.include?(attr[:origin_url]) }
    attributes
  end
end
