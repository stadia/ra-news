# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module DateParsing
    PUBLISHED_META_SELECTORS = [
      'meta[property="article:published_time"]',
      'meta[property="og:published_time"]',
      'meta[name="pubdate"]',
      'meta[name="publish_date"]',
      'meta[name="published_date"]',
      'meta[name="date"]',
      'meta[itemprop="datePublished"]'
    ].freeze

    PUBLISHED_DATE_SELECTORS = [
      "time[datetime]",
      ".published",
      ".published-at",
      ".post-date",
      ".entry-date",
      ".article-date",
      '[itemprop="datePublished"]'
    ].freeze

    JSON_LD_ARTICLE_TYPES = %w[NewsArticle Article BlogPosting].freeze

    class << self
      #: (Nokogiri::HTML4::Document doc) -> Time?
      def meta_published_at(doc)
        PUBLISHED_META_SELECTORS.each do |selector|
          element = doc.at_css(selector)
          next if element.nil?

          candidate = parse_value(element["content"] || element["datetime"] || element.text)
          return candidate if candidate
        end

        nil
      end

      #: (Nokogiri::HTML4::Document doc) -> Time?
      def json_ld_published_at(doc)
        doc.css('script[type="application/ld+json"]').each do |node|
          payload = parse_json_ld(node.text)
          next if payload.nil?

          candidate = extract_from_json_ld(payload)
          return candidate if candidate
        end

        nil
      end

      #: (Nokogiri::HTML4::Document doc) -> Time?
      def selector_published_at(doc)
        PUBLISHED_DATE_SELECTORS.each do |selector|
          doc.css(selector).each do |element|
            candidate = parse_value(element["datetime"] || element["content"] || element.text)
            return candidate if candidate
          end
        end

        if (date_element = doc.at_css(".date"))
          parse_value(date_element.text)
        end
      end

      #: (Nokogiri::HTML4::Document doc) -> Time?
      def text_published_at(doc)
        text = doc.at_css("article, main, body")&.text.to_s.squish
        return if text.blank?

        parse_value(text[%r{\b\d{4}-\d{1,2}-\d{1,2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:\d{2})\b}]) ||
          parse_value(text[/\b[A-Za-z]+\s+\d{1,2},\s+\d{4}\b/]) ||
          parse_value(text[%r{\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b}]) ||
          parse_value(text[/\b\d{4}년\s*\d{1,2}월\s*\d{1,2}일\b/])
      end

      private

      #: (String text) -> untyped
      def parse_json_ld(text)
        return if text.blank?

        JSON.parse(text)
      rescue JSON::ParserError
        nil
      end

      #: (untyped payload) -> Time?
      def extract_from_json_ld(payload)
        case payload
        when Array
          payload.each do |item|
            candidate = extract_from_json_ld(item)
            return candidate if candidate
          end
          nil
        when Hash
          nodes = []
          nodes.concat(Array(payload["@graph"])) if payload["@graph"].present?
          nodes << payload

          prioritized_nodes = nodes.partition { |node| article_json_ld?(node) }.flatten
          prioritized_nodes.each do |node|
            candidate = parse_value(node["datePublished"] || node["dateCreated"] || node["uploadDate"])
            return candidate if candidate
          end
          nil
        end
      end

      #: (Hash[String, untyped] node) -> bool
      def article_json_ld?(node)
        Array(node["@type"]).any? { |type| JSON_LD_ARTICLE_TYPES.include?(type) }
      end

      #: (untyped value) -> Time?
      def parse_value(value)
        return if value.blank?

        normalized = value.to_s.strip
        korean_match = normalized.match(/\A(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일\z/)
        if korean_match
          return Time.zone.local(korean_match[1].to_i, korean_match[2].to_i, korean_match[3].to_i)
        end

        Time.zone.parse(normalized)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
