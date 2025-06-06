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

    feed = site.init_client&.feed(site.path)
    return if feed.nil?

    feed.items.each do |item|
      attrs = nil
      case item
      when RSS::Atom::Feed::Entry
        attrs = { title: item.title.content, url: item.link.href, origin_url: item.link.href, published_at: item.published.content }
      when RSS::Rss::Channel::Item
        attrs = { title: item.title, url: item.link, origin_url: item.link, published_at: item.pubDate }
      end
      next if attrs.nil? || attrs.empty?

      break if site.last_checked_at > attrs[:published_at]

      Article.exists?(origin_url: attrs[:origin_url]) and next

      Article.create(attrs.merge(site:, created_at: attrs[:published_at], updated_at: attrs[:published_at]))
    end

    site.update(last_checked_at: Time.zone.now)
  end
end
