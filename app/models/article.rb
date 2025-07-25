# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  include PgSearch::Model

  include Discard::Model

  has_neighbors :embedding

  self.discard_column = :deleted_at

  multisearchable against: [ :title, :title_ko, :summary_key, :summary_detail, :body ], if: lambda { |record| record.deleted_at.nil? }

  scope :full_text_search_for, ->(term) do
    joins(:pg_search_document).merge(
      PgSearch.multisearch(term).where(searchable_type: self.name)
    )
  end

  scope :related, -> { where(is_related: true) }

  scope :unrelated, -> { where(is_related: false) }

  pg_search_scope :title_matching, against: [ :title, :title_ko ], using: { tsearch: { dictionary: "korean" } }

  pg_search_scope :body_matching, against: :body, using: { tsearch: { dictionary: "english" } }

  belongs_to :user, optional: true

  belongs_to :site, optional: true

  has_many :comments, dependent: :nullify

  validates :url, :origin_url, presence: true, uniqueness: true

  validates :slug, uniqueness: true, allow_blank: true

  before_create :generate_metadata

  acts_as_taggable_on :tags

  after_create do
    ArticleJob.perform_later(id) if deleted_at.nil?
    Rails.cache.delete("rss_articles")
  end

  after_discard do
    Rails.cache.delete("rss_articles")
  end

  after_commit do
    # ArticleJob.perform_later(id) if saved_change_to_url? && deleted_at.nil? # Ensure deleted_at is checked here too
  end

  before_save do
    # published_at이 없으면 현재 시간으로 설정.
    # 단, LLM 요약 전에는 원본 URL에서 최대한 추출하는 것이 좋으므로,
    # 이 부분은 generate_metadata 내에서 처리되도록 합니다.
    self.published_at ||= Time.zone.now
  end

  # YouTube URL의 정규화된 호스트를 상수로 정의
  YOUTUBE_NORMALIZED_HOST = "www.youtube.com".freeze

  IGNORE_HOSTS = %w[meetup.com maily.so github.com bsky.app bsky.social threadreaderapp.com threads.com threads.net x.com beehiiv.com join1440.com visualstudio.com ruby.social elk.zone
    indieweb.social rubygems.org javascriptweekly.com postgresweekly.com rubyweekly.com breezy.hr remoterocketship.com localhost
    linkedin.com meet.google.com twitch.tv inf.run lu.ma shortruby.com twitter.com facebook.com daily.dev libhunt.com hotwireweekly.com reddit.com].freeze #: Array[String]

  def generate_metadata #: void
    return unless url.is_a?(String)

    response = fetch_url_content
    return unless response

    handle_redirection(response)

    set_initial_url_and_host # URL 및 호스트 초기 설정, 삭제 여부 판단

    if is_youtube?
      set_youtube_metadata
    else
      set_webpage_metadata(response.body)
    end

    self.slug = "#{Time.zone.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4)}" unless slug.present?

    # slug 중복 처리 (slug가 설정된 후에만 확인)
    self.slug = "#{slug}-#{SecureRandom.hex(4)}" if slug.present? && Article.exists?(slug: self.slug)
  end

  def youtube_id #: String?
    # nil 체크를 포함하여 안전하게 접근
    if url.is_a?(String)
      uri = URI.parse(url)
      if uri.query.present?
        URI.decode_www_form(uri.query).to_h["v"]
      elsif uri.path.start_with?("/live")
        uri.path.split("/").last
      end
    end
  rescue URI::InvalidURIError
    logger.error "Invalid URI for youtube_id: #{url}"
    nil
  end

  def update_slug #: bool
    new_slug = is_youtube? ? youtube_id : URI.parse(url).path.split("/").last.split(".").first
    update(slug: new_slug)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for slug update: #{url}"
    false
  end

  def update_published_at #: bool
    response = fetch_url_content
    return false unless response

    update(published_at: url_to_published_at || extract_published_at_from_content(response.body) || Time.zone.now)
  end

  # slug로 Article을 찾는 메서드
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  # 도메인과 서브도메인을 정확히 체크하는 클래스 메서드
  #: (String url) -> bool
  def self.should_ignore_url?(url)
    return true if url.blank?

    begin
      uri = URI.parse(url)
      host = uri.host&.downcase
      return true if host.blank?

      IGNORE_HOSTS.any? do |ignore_host|
        # 정확한 도메인 매칭
        host == ignore_host ||
        host.end_with?(".#{ignore_host}") ||
        # 추가적으로 www 서브도메인도 고려
        (host.start_with?("www.") && host[4..] == ignore_host) ||
        # 서브도메인 매칭
        host.start_with?("job")
      end
    rescue URI::InvalidURIError => e
      logger.warn "Invalid URI detected: #{url} - #{e.message}"
      true
    end
  end

  def user_name
    return user&.name.present? ? user.name : "알 수 없음" if user.present?

    if site.present?
      site.base_uri.present? ? "#{site.name} (#{site.base_uri})" : site.name
    else
      "알 수 없음"
    end
  end

  private

  def set_initial_url_and_host #: void
    parsed_url = URI.parse(url)
    if parsed_url.respond_to?(:query) && parsed_url.query
      query_params = URI.decode_www_form(parsed_url.query || "").to_h
      query_params.except!("utm_source", "utm_medium", "utm_campaign", "_bhlid", "ref", "utm_content", "utm_term") if query_params.is_a?(Hash)
      query_params.except!("t", "feature") if parsed_url.host&.match?(/youtube/i)
      self.url = query_params.empty? ? "#{parsed_url.scheme}://#{parsed_url.host}#{parsed_url.path}" : "#{parsed_url.scheme}://#{parsed_url.host}#{parsed_url.path}?#{query_params.map { |k, v| "#{k}=#{v}" }.join('&')}"
    end
    self.host = parsed_url.host
    self.is_youtube = true if host&.match?(/youtube/i)
    # IGNORE_HOSTS 패턴에 맞는 호스트이거나 경로가 너무 짧으면 discard
    self.deleted_at = Time.zone.now if !is_youtube && parsed_url.path.nil? || parsed_url.path.size < 2 || Article.should_ignore_url?(parsed_url.to_s)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for initial URL parsing: #{url}"
    self.deleted_at = Time.zone.now # 유효하지 않은 URL은 삭제 처리
  end

  def set_youtube_metadata #: void
    self.slug = youtube_id
    # self.url = "https://#{YOUTUBE_NORMALIZED_HOST}/watch?v=#{youtube_id}"
    video = Yt::Video.new id: youtube_id
    self.published_at = video.published_at if video&.published_at.is_a?(Time)
    self.title = video.title if video&.title.is_a?(String)
  rescue Yt::Error => e # Yt 라이브러리 관련 오류 처리
    logger.error "YouTube API error for video ID #{youtube_id}: #{e.message}"
    # 필요하다면 title, published_at을 nil 또는 기본값으로 설정
  end

  #: (String body) -> void
  def set_webpage_metadata(body)
    logger.debug "Setting webpage metadata for #{url}"
    return if deleted_at.present?

    self.slug = URI.parse(url)&.path.split("/").last.split(".").first
    self.published_at = url_to_published_at || extract_published_at_from_content(body) || Time.zone.now
    return if title.present?

    doc = Nokogiri::HTML5(body)
    temp_title = doc.at("title")&.text
    self.title = temp_title.strip.gsub(/\s+/, " ") if temp_title.is_a?(String)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for webpage metadata: #{url}"
    # slug, published_at, title 등에 대한 기본값 설정 또는 오류 처리
  end

  #: (Faraday::Response response) -> void
  def handle_redirection(response, count = 0)
    logger.debug response.status
    logger.debug count
    return unless response.status.between?(300, 399) && response.headers["location"]
    return if count > 3

    logger.debug response.headers["location"]
    # 3xx 응답인 경우 리다이렉트된 URL을 사용
    redirect_url = response.headers["location"]
    self.url = if redirect_url.start_with?("http")
                 redirect_url
    else
                 URI.join(url, redirect_url).to_s
    end

    response = fetch_url_content
    handle_redirection(response, count + 1)
  end

  def fetch_url_content #: Faraday::Response?
    Faraday.get(url)
  rescue Faraday::Error => e
    logger.error "Error fetching URL #{url}: #{e.message}"
    nil
  end

  def url_to_published_at #: DateTime?
    match_data = URI.parse(url).path.match(%r{(\d{4})[/-](\d{1,2})[/-](\d{1,2})})
    return unless match_data

    Time.zone.parse("#{match_data[1]}-#{match_data[2]}-#{match_data[3]}")
  rescue URI::InvalidURIError
    logger.error "Invalid URI for published_at extraction: #{url}"
    nil
  end

  #: (String body) -> DateTime?
  def extract_published_at_from_content(body)
    doc = Nokogiri::HTML(body)
    published_at = if doc.at("time").present?
      time_element = doc.at("time")
      if time_element.[]("datetime").present?
        Time.zone.parse(time_element.[]("datetime"))
      else
        time_element.text.present? ? Time.zone.parse(time_element.text) : nil
      end
    elsif doc.css(".date").present?
      # Nokogiri::HTML::Document에서 class가 "date"인 요소를 찾는 방법
      date_element = doc.css(".date").first
      date_element.text.present? ? Time.zone.parse(date_element.text) : nil
    end
    return published_at if published_at.is_a?(Time)

    if body.strip.match(/([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})/)
      match_data = body.strip.match(/([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})/)
      Time.zone.parse("#{match_data[3]}-#{match_data[1]}-#{match_data[2]}")
    elsif body.strip.match(%r{(\d{4})[/-](\d{1,2})[/-](\d{1,2})})
      match_data = body.strip.match(%r{(\d{4})[/-](\d{1,2})[/-](\d{1,2})})
      Time.zone.parse("#{match_data[1]}-#{match_data[2]}-#{match_data[3]}")
    else
      nil
    end
  rescue StandardError => e
    logger.error "Error parsing published_at: #{e.message}"
    nil
  end
end
