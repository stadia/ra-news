# frozen_string_literal: true
# rbs_inline: enabled

require "rss"

module Reddit
  BASE_URL = "https://www.reddit.com"
  SUBREDDIT = "ruby+rails"
  USER_AGENT = "ruby-news/1.0 (by /u/ruby-news-bot)"
  REDDIT_HOSTS = %w[reddit.com www.reddit.com old.reddit.com new.reddit.com redd.it].freeze

  class << self
    # Reddit JSON API를 우선 사용하고, 인증 없는 JSON 요청이 차단되면 Atom feed로 fallback한다.
    #
    # sort: :hot, :new, :top, :rising, :controversial
    # period: :hour, :day, :week, :month, :year, :all (top/controversial에서만 사용)
    # limit: 1~100
    #
    #: (?sort: Symbol, ?period: Symbol, ?limit: Integer) -> Array[Hash[String, untyped]]
    def feed(sort: :top, period: :day, limit: 50)
      fetch_json_posts(sort:, period:, limit:) || fetch_atom_posts(sort:, period:, limit:)
    rescue Faraday::Error, JSON::ParserError, RSS::Error => e
      Rails.logger.warn "Reddit feed fetch failed: #{e.class} - #{e.message}"
      []
    end

    private

    #: (sort: Symbol, period: Symbol, limit: Integer) -> Array[Hash[String, untyped]]?
    def fetch_json_posts(sort:, period:, limit:)
      response = Faraday.get("#{BASE_URL}/r/#{SUBREDDIT}/#{sort}.json") do |req|
        apply_headers(req)
        apply_params(req, sort:, period:, limit:)
        apply_timeouts(req)
      end

      return nil unless response.success?

      JSON.parse(response.body).dig("data", "children")&.map { |child| child["data"] } || []
    end

    #: (sort: Symbol, period: Symbol, limit: Integer) -> Array[Hash[String, untyped]]
    def fetch_atom_posts(sort:, period:, limit:)
      response = Faraday.get("#{BASE_URL}/r/#{SUBREDDIT}/#{sort}.rss") do |req|
        apply_headers(req)
        apply_params(req, sort:, period:, limit:)
        apply_timeouts(req)
        req.headers["Accept"] = "application/atom+xml, application/rss+xml, application/xml, text/xml"
      end

      return [] unless response.success?

      feed = RSS::Parser.parse(response.body, false)
      feed.items.map { |entry| atom_entry_to_post(entry) }.compact
    end

    #: (untyped entry) -> Hash[String, untyped]?
    def atom_entry_to_post(entry)
      content = entry.content&.content.to_s
      external_url = external_link_from_content(content)

      {
        "title" => entry.title&.content.to_s,
        "url" => external_url || entry.link&.href.to_s,
        "created_utc" => entry.published&.content&.to_i || entry.updated&.content&.to_i,
        "is_self" => external_url.nil?,
        "selftext_html" => content
      }
    end

    #: (String content) -> String?
    def external_link_from_content(content)
      doc = Nokogiri::HTML5.fragment(CGI.unescapeHTML(content))
      link = doc.css("a").find do |anchor|
        anchor.text.strip == "[link]" && external_url?(anchor["href"])
      end

      link&.[]("href")
    end

    #: (String? url) -> bool
    def external_url?(url)
      return false if url.blank?

      host = URI.parse(url).host&.downcase
      return false if host.blank?

      REDDIT_HOSTS.none? { |reddit_host| host == reddit_host || host.end_with?(".#{reddit_host}") }
    rescue URI::InvalidURIError
      false
    end

    #: (untyped req) -> void
    def apply_headers(req)
      req.headers["User-Agent"] = USER_AGENT
      req.headers["Accept"] = "application/json"
    end

    #: (untyped req, sort: Symbol, period: Symbol, limit: Integer) -> void
    def apply_params(req, sort:, period:, limit:)
      req.params["t"] = period.to_s if %i[top controversial].include?(sort)
      req.params["limit"] = limit
    end

    #: (untyped req) -> void
    def apply_timeouts(req)
      req.options.open_timeout = HttpTimeouts::OPEN
      req.options.timeout = HttpTimeouts::REQUEST
    end
  end
end
