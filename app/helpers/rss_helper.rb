# typed: true
# rbs_inline: enabled

module RssHelper
  protected

  def create_article(attributes)
    logger.debug attributes
    attributes = attributes.merge(user: User.find_by(username: "bot"))

    article = Article.create_with(attributes)
                     .find_or_create_by!(origin_url: attributes[:origin_url])

    if article.previously_new_record?
      logger.info "Created article for #{attributes[:url]}"
      sleep 1
    end
  rescue ActiveRecord::ActiveRecordError => e
    logger.error "Failed to create article for #{attributes[:url]}: #{e.message}"
  rescue StandardError => e
    logger.error "Unexpected error creating article for #{attributes[:url]}: #{e.message}"
  end

  # Fetches and parses the RSS feed for a site.
  #: (Site site) -> (RSS::Rss | RSS::Atom::Feed)?
  def fetch_feed(site)
    url = site.url
    return nil if url.nil? || url.blank?

    RssClient.feed(url)
  rescue RSS::NotWellFormedError, RSS::Error, REXML::ParseException => e
    logger.warn "RSS parsing error for site #{site.id} (#{site.url}): #{e.class} - #{e.message}"
    nil
  rescue StandardError => e
    logger.error "RSS parsing error for site #{site.id}: #{e.message}"
    raise e
  end

  # Returns the items from an RSS or Atom feed.
  #: ((RSS::Rss | RSS::Atom::Feed) feed) -> Array[RSS::Rss::Channel::Item | RSS::Atom::Feed::Entry]
  def feed_items(feed)
    case feed
    when RSS::Rss
      feed.items
    when RSS::Atom::Feed
      feed.entries
    end
  end

  # Extracts attributes from a feed item.
  #: ((RSS::Rss::Channel::Item | RSS::Atom::Feed::Entry) item) -> Hash[Symbol, untyped]?
  def extract_item_attributes(item)
    attrs = case item
    when RSS::Atom::Feed::Entry
      url = item.links.find { it.rel == "alternate" }&.href || item.link&.href
      {
        title: item.title&.content,
        url: url,
        origin_url: url,
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
