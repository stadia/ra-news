# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module MetadataPreparation
    extend FunctionLogger
    module_function

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

    TRACKING_QUERY_KEYS = %w[
      utm_source
      utm_medium
      utm_campaign
      _bhlid
      ref
      utm_content
      utm_term
      ck_subscriber_id
    ].freeze

    YOUTUBE_QUERY_KEYS = %w[t feature si].freeze

    MAX_REDIRECTS = 3

    #: (String url) -> Faraday::Response?
    def fetch_url_content(url)
      Faraday.get(url)
    rescue Faraday::Error => e
      logger.error "Error fetching URL #{url}: #{e.message}"
      nil
    end

    #: (Article article, Faraday::Response response, ?Integer count) -> Faraday::Response?
    def follow_redirection(article, response, count = 0)
      return response if response.nil?
      return response unless response.status.between?(300, 399) && response.headers["location"]
      return response if count > MAX_REDIRECTS

      redirect_url = response.headers["location"]
      article.url = if redirect_url.start_with?("http")
        redirect_url
      else
        URI.join(article.url, redirect_url).to_s
      end

      next_response = fetch_url_content(article.url)
      follow_redirection(article, next_response, count + 1)
    end

    #: (String url) -> DateTime?
    def url_to_published_at(url)
      match_data = URI.parse(url).path.match(%r{(\d{4})[/-](\d{1,2})[/-](\d{1,2})})
      return unless match_data

      Time.zone.parse("#{match_data[1]}-#{match_data[2]}-#{match_data[3]}")
    rescue URI::InvalidURIError
      logger.error "Invalid URI for published_at extraction: #{url}"
      nil
    rescue ArgumentError => e
      logger.error e
      nil
    end

    #: (String body) -> DateTime?
    def extract_published_at_from_content(body)
      doc = Nokogiri::HTML(body)
      meta_published_at(doc) ||
        json_ld_published_at(doc) ||
        selector_published_at(doc) ||
        text_published_at(doc)
    rescue StandardError => e
      logger.error "Error parsing published_at: #{e.message}"
      nil
    end

    #: (Article article, String body) -> Time
    def published_at_for(article, body)
      candidate =
        article.published_at ||
        url_to_published_at(article.url) ||
        extract_published_at_from_content(body)

      normalize_published_at(candidate)
    end

    #: (String title) -> String
    def build_slug(title)
      base = title.presence
      base ? base.parameterize.presence || random_slug : random_slug
    end

    #: (URI::Generic parsed_url) -> String
    def normalized_url(parsed_url)
      filtered_query_pairs = URI.decode_www_form(parsed_url.query.to_s)
                                .reject { |key, _value| TRACKING_QUERY_KEYS.include?(key) }
      if parsed_url.host&.match?(/youtube/i)
        filtered_query_pairs.reject! { |key, _value| YOUTUBE_QUERY_KEYS.include?(key) }
      end

      normalized = +"#{parsed_url.scheme}://#{parsed_url.host}#{parsed_url.path}"
      normalized << "?#{URI.encode_www_form(filtered_query_pairs)}" if filtered_query_pairs.any?
      normalized
    end

    #: (Article article, URI::Generic parsed_url) -> bool
    def should_discard_url?(article, parsed_url)
      (!article.is_youtube && (parsed_url.path.nil? || parsed_url.path.size < 2)) ||
        Article.should_ignore_url?(parsed_url.to_s)
    end

    #: (DateTime? candidate) -> Time
    def normalize_published_at(candidate)
      return Time.zone.now if candidate.nil?
      return Time.zone.now if candidate.future?

      candidate
    end

    def meta_published_at(doc)
      PUBLISHED_META_SELECTORS.each do |selector|
        element = doc.at_css(selector)
        next if element.nil?

        candidate = parse_published_at_value(element["content"] || element["datetime"] || element.text)
        return candidate if candidate
      end

      nil
    end

    def json_ld_published_at(doc)
      doc.css('script[type="application/ld+json"]').each do |node|
        payload = parse_json_ld(node.text)
        next if payload.nil?

        candidate = extract_published_at_from_json_ld(payload)
        return candidate if candidate
      end

      nil
    end

    def selector_published_at(doc)
      PUBLISHED_DATE_SELECTORS.each do |selector|
        doc.css(selector).each do |element|
          candidate = parse_published_at_value(element["datetime"] || element["content"] || element.text)
          return candidate if candidate
        end
      end

      if (date_element = doc.at_css(".date"))
        parse_published_at_value(date_element.text)
      end
    end

    def text_published_at(doc)
      text = doc.at_css("article, main, body")&.text.to_s.squish
      return if text.blank?

      parse_published_at_value(text[%r{\b\d{4}-\d{1,2}-\d{1,2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:\d{2})\b}]) ||
        parse_published_at_value(text[/\b[A-Za-z]+\s+\d{1,2},\s+\d{4}\b/]) ||
        parse_published_at_value(text[%r{\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b}]) ||
        parse_published_at_value(text[/\b\d{4}년\s*\d{1,2}월\s*\d{1,2}일\b/])
    end

    def parse_json_ld(text)
      return if text.blank?

      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end

    def extract_published_at_from_json_ld(payload)
      case payload
      when Array
        payload.each do |item|
          candidate = extract_published_at_from_json_ld(item)
          return candidate if candidate
        end
        nil
      when Hash
        nodes = []
        nodes.concat(Array(payload["@graph"])) if payload["@graph"].present?
        nodes << payload

        prioritized_nodes = nodes.partition { |node| article_json_ld?(node) }.flatten
        prioritized_nodes.each do |node|
          candidate = parse_published_at_value(node["datePublished"] || node["dateCreated"] || node["uploadDate"])
          return candidate if candidate
        end
        nil
      end
    end

    def article_json_ld?(node)
      Array(node["@type"]).any? { |type| JSON_LD_ARTICLE_TYPES.include?(type) }
    end

    def parse_published_at_value(value)
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

    def random_slug
      "#{Time.zone.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4)}"
    end
  end
end
