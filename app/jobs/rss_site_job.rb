# frozen_string_literal: true

# rbs_inline: enabled

class RssSiteJob < ApplicationJob
  #: (id Integer) -> void
  def perform(id = nil)
    site = Site.find_by(id:)
    return if site.nil?

    feed = site.init_client&.feed(site.path)
    return if feed.nil?

    last_checked_at = Time.zone.now
    user = User.first

    feed.items.each do |item|
      attrs = nil
      case item
      when RSS::Atom::Feed::Entry
        !site.last_checked_at.nil? && site.last_checked_at > item.published.content and next

        attrs = { title: item.title.content, url: item.link.href, origin_url: item.link.href, published_at: item.published.content, user: }
      when RSS::Rss::Channel::Item
        !site.last_checked_at.nil? && site.last_checked_at > item.pubDate and next

        attrs = { title: item.title, url: item.link, origin_url: item.link, published_at: item.pubDate, user: }
      end
      next if attrs.nil? || attrs.empty?

      Article.exists?(origin_url: attrs[:origin_url]) and next

      Article.create(attrs)
    end

    site.update(last_checked_at:)
  end
end
