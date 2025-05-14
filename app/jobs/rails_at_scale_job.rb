# frozen_string_literal: true

# rbs_inline: enabled

class RailsAtScaleJob < ApplicationJob
  def perform #: void
    site = Site.find_by(client: "RailsAtScale")
    feed = site.execute_client&.feed
    return if feed.nil?

    last_checked_at = Time.zone.now
    user = User.first
    site.last_checked_at
    feed.items.each do |item|
      site.last_checked_at > item.published.content and next

      Article.create(title: item.title.content, url: item.link.href, published_at: item.published.content, user:)
    end

    site.update(last_checked_at:)
  end
end
