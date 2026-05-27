# frozen_string_literal: true
# rbs_inline: enabled

class RedditSiteJob < ApplicationJob
  # Reddit 내부 도메인 (self-post 판별용)
  REDDIT_HOSTS = %w[
    reddit.com
    www.reddit.com
    old.reddit.com
    new.reddit.com
    redd.it
    v.redd.it
    i.redd.it
    preview.redd.it
    external-preview.redd.it
    github.com
  ].freeze

  def perform
    site = Site.reddit.first
    return if site.nil?

    %i[top hot].each do |sort|
      params = sort == :top ? { sort: :top, period: :day, limit: 50 } : { sort: :hot, limit: 50 }
      Reddit.feed(**params).each { |post| process_post(post, site) }
    end

    site.update(last_checked_at: Time.zone.now)
  end

  private

  #: (Hash[String, untyped] post, Site site) -> void
  def process_post(post, site)
    post_url = post["url"]
    return if post_url.blank?

    # self-post인 경우: 본문의 외부 링크를 추출
    if post["is_self"]
      extract_external_links(post["selftext_html"]).each do |url|
        create_article(url:, site:, post:)
      end
      return
    end

    # 링크 포스트인 경우: url이 곧 외부 링크
    create_article(url: post_url, site:, post:) if external_link?(post_url)
  end

  #: (url: String, site: Site, post: Hash[String, untyped]) -> void
  def create_article(url:, site:, post:)
    return if Article.exists?(origin_url: url)
    return if Articles::Utils.should_ignore_url?(url)

    begin
      parsed_url = URI.parse(url)
      return if parsed_url.path.nil? || parsed_url.path.size < 2
    rescue URI::InvalidURIError
      return
    end

    Article.create!(
      title: post["title"],
      url: url,
      origin_url: url,
      published_at: post["created_utc"] ? Time.at(post["created_utc"]) : nil,
      site: site,
      user: User.first_bot
    )
    sleep 1
  rescue ActiveRecord::ActiveRecordError => e
    logger.error "Failed to create article for #{url}: #{e.message}"
  end

  #: (String? html) -> Array[String]
  def extract_external_links(html)
    return [] if html.blank?

    # Reddit의 selftext_html은 HTML 엔티티로 인코딩되어 있음
    decoded = CGI.unescapeHTML(html)
    doc = Nokogiri::HTML5.fragment(decoded)
    links = doc.css("a").map { |a| a["href"] }.compact.uniq

    links.select { |link| external_link?(link) }
  end

  #: (String url) -> bool
  def external_link?(url)
    return false if url.blank?

    begin
      uri = URI.parse(url)
      host = uri.host&.downcase
      return false if host.blank?

      REDDIT_HOSTS.none? { |reddit_host| host == reddit_host || host.end_with?(".#{reddit_host}") }
    rescue URI::InvalidURIError
      false
    end
  end
end
