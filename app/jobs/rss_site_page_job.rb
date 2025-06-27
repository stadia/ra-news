# frozen_string_literal: true

# rbs_inline: enabled

class RssSitePageJob < ApplicationJob
  include RssHelper
  include LinkHelper

  def self.enqueue_all
    RssSitePageJob.perform_later(Site.rss.order("id ASC").pluck(:id))
  end

  # Performs the job for a given site ID.
  #: (ids Array[int] | int) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)
    feed = fetch_feed(site)
    unless feed
      RssSitePageJob.perform_later(ids) unless ids.empty?
      return
    end

    attributes = feed_items(feed).map { |item| extract_item_attributes(item) }.compact

    if site.last_checked_at
      attributes.reject! { |attr| attr[:published_at] < site.last_checked_at }
    end
    return [] if attributes.empty?

    links = []
    attributes.each do |attr|
      next if attr[:url].end_with?("pdf")

      response = Faraday.get(attr[:url])
      next unless response.status.between?(200, 299)

      html_doc = Nokogiri::HTML5(response.body)
      # 링크 추출
      html_doc.css("a[href]").each {
        next if it["href"].blank?
        links << it["href"] if it["href"].is_a?(String)
      }
    end

    if links.empty?
      RssSitePageJob.perform_later(ids) unless ids.empty?
      return
    end

    links = links.uniq

    links.each do |link|
      processed_link = extract_link(link)
      next if processed_link.blank? || processed_link.end_with?("pdf") || Article.should_ignore_url?(processed_link)

      logger.info "Processing link: #{processed_link}"
      next if Article.exists?(url: processed_link) || Article.exists?(origin_url: processed_link)

      create_article(origin_url: processed_link, url: processed_link, site: site)
    end

    site.update!(last_checked_at: Time.zone.now)
    RssSitePageJob.perform_later(ids) unless ids.empty?
  end
end
