# frozen_string_literal: true

# rbs_inline: enabled

class RssSiteJob < ApplicationJob
  #: (id Integer) -> void
  def perform(id = nil)
    if id.nil?
      Site.all.select { |site| site.is_rss? }.map { RssSiteJob.perform_later(it.id) }
      return
    end

    site = Site.find_by(id:)
    return if site.nil?

    begin
      feed = site.init_client&.feed(site.path)
      return unless feed

      process_feed_items(feed, site)
      site.update(last_checked_at: Time.zone.now)
    rescue => e
      logger.error "RSS parsing error for site #{site.id}: #{e.message}"
    end
  end

  private

  #: (RSS::Rss | RSS::Atom::Feed feed, Site site) -> void
  def process_feed_items(feed, site)
    items = case feed
    when RSS::Rss
              feed.items
    when RSS::Atom::Feed
              feed.entries
    else
              []
    end

    items.each do |item|
      attrs = extract_item_attributes(item)
      next unless attrs

      # 이미 체크한 시간보다 오래된 항목이면 중단
      break if site.last_checked_at && attrs[:published_at] < site.last_checked_at

      # 중복 체크
      next if Article.exists?(origin_url: attrs[:origin_url])

      Article.create(attrs.merge(site:,
        created_at: attrs[:published_at],
        updated_at: attrs[:published_at]
      ))
    end
  end

  #: (RSS::Rss::Channel::Item | RSS::Atom::Feed::Entry item) -> Hash?
  def extract_item_attributes(item)
    case item
    when RSS::Atom::Feed::Entry
      {
        title: item.title&.content,
        url: item.link&.href,
        origin_url: item.link&.href,
        published_at: parse_time(item.published&.content) || Time.zone.now
      }
    when RSS::Rss::Channel::Item
      {
        title: item.title,
        url: item.link,
        origin_url: item.link,
        published_at: parse_time(item.pubDate) || Time.zone.now
      }
    end
  end

  #: (String | Time | nil time_value) -> Time?
  def parse_time(time_value)
    case time_value
    when Time
      time_value
    when String
      Time.zone.parse(time_value)
    else
      nil
    end
  end
end
