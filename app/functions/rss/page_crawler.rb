# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Rss
  module PageCrawler
    extend FunctionLogger

    class << self
      include RssHelper
      include LinkHelper

      #: (Site site) -> void
      def crawl(site)
        feed = fetch_feed(site)
        return unless feed

        attributes = feed_items(feed).map { |item| extract_item_attributes(item) }.compact
        attributes.reject! { |attr| attr[:published_at].present? && attr[:published_at] < site.last_checked_at } if site.last_checked_at
        return if attributes.empty?

        links = collect_links(attributes).uniq
        return if links.empty?

        links.each { |link| process_link(link, site) }
      end

      private

      #: (Array[Hash[Symbol, untyped]] attributes) -> Array[String]
      def collect_links(attributes)
        attributes.flat_map { |attr| hrefs_from(attr) }
      end

      # 단일 attr에서 링크를 수집한다. 실패 시 빈 배열을 반환해 전체 크롤을 막지 않는다.
      #: (Hash[Symbol, untyped] attr) -> Array[String]
      def hrefs_from(attr)
        url = attr[:url].to_s.strip
        return [] if url.blank? || url.downcase.end_with?("pdf")

        response = Faraday.get(url) do |req|
          req.options.open_timeout = HttpTimeouts::OPEN
          req.options.timeout = HttpTimeouts::REQUEST
        end
        return [] unless response.status.between?(200, 299)

        Nokogiri::HTML5(response.body).css("a[href]").filter_map do |a|
          href = a["href"]
          href if href.is_a?(String) && href.present?
        end
      rescue StandardError => e
        logger.error "Error collecting links from #{url.presence || attr.inspect}: #{e.message}"
        []
      end

      #: (String link, Site site) -> void
      def process_link(link, site)
        processed_link = extract_link(link)
        return if processed_link.blank? || processed_link.end_with?("pdf") || Articles::Utils.should_ignore_url?(processed_link)

        logger.info "Processing link: #{processed_link}"
        return if Article.exists?(url: processed_link) || Article.exists?(origin_url: processed_link)

        create_article(origin_url: processed_link, url: processed_link, site: site)
      rescue StandardError => e
        logger.error "Error processing link #{link}: #{e.message}"
      end
    end
  end
end
