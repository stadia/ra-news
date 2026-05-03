module RssHelper
  protected

  def create_article(attributes)
    logger.debug attributes
    # Double check existence to prevent race conditions
    return if Article.exists?(origin_url: attributes[:origin_url])

    attributes.merge!(user: User.find_by(username: "bot"))
    Article.create!(attributes)
    logger.info "Created article for #{attributes[:url]}"
    sleep 1
  rescue ActiveRecord::ActiveRecordError => e
    logger.error "Failed to create article for #{attributes[:url]}: #{e.message}"
  rescue StandardError => e
    logger.error "Unexpected error creating article for #{attributes[:url]}: #{e.message}"
  end

  # Fetches and parses the RSS feed for a site.
  #: (Site site) -> RSS::Rss || RSS::Atom::Feed
  def fetch_feed(site)
    RssClient.feed(site.url)
  rescue StandardError => e
    logger.error "RSS parsing error for site #{site.id}: #{e.message}"
    raise e
  end

  # Returns the items from an RSS or Atom feed.
  #: (RSS::Rss || RSS::Atom::Feed feed) -> Array[RSS::Rss::Channel::Item || RSS::Atom::Feed::Entry]
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
  #: (RSS::Rss::Channel::Item || RSS::Atom::Feed::Entry item) -> Hash?
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
