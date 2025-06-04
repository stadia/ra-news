# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  include PgSearch::Model

  multisearchable against: [ :title, :title_ko, :summary_key, :summary_detail ], if: lambda { |record| record.deleted_at.nil? }

  scope :full_text_search_for, ->(term) do
    joins(:pg_search_document).merge(
      PgSearch.multisearch(term).where(searchable_type: self.name)
    )
  end

  belongs_to :user, optional: true

  belongs_to :site, optional: true

  validates :url, :origin_url, presence: true, uniqueness: true

  validates :slug, uniqueness: true, allow_blank: true

  before_create :generate_metadata

  acts_as_taggable_on :tags

  after_create do
    next unless url.is_a?(String)

    ArticleJob.perform_later(id) if deleted_at.nil?
  end

  after_commit do
    next unless saved_change_to_url?

    ArticleJob.perform_later(id) if deleted_at.nil?
  end

  before_save do
    published_at = Time.zone.now if published_at.blank?
  end

  IGNORE_HOSTS = %w[meetup.com maily.so github.com bsky.app bsky.social threadreaderapp.com threads.com threads.net x.com linkedin.com meet.google.com twitch.tv inf.run lu.ma shortruby.com twitter.com facebook.com daily.dev] #: Array[String]

  def generate_metadata #: void
    return unless url.is_a?(String)

    response = fetch_url_content
    return unless response

    handle_redirection(response)

    parsed_url = URI.parse(url)
    self.host = parsed_url.host
    self.deleted_at = Time.zone.now if parsed_url.path.nil? || parsed_url.path.size < 2 || Article::IGNORE_HOSTS.any? { |pattern| parsed_url.host&.match?(/#{pattern}/i) }
    self.is_youtube = true if host&.match?(/youtube/i)

    if is_youtube?
      set_youtube_metadata
    else
      set_webpage_metadata(response.body)
    end
    self.slug = "#{slug}-#{SecureRandom.hex(4)}" if Article.exists?(slug: self.slug)
  end

  def youtube_id #: String?
    URI.decode_www_form(URI.parse(url).query).to_h["v"]
  end

  def update_slug #: bool
    update(slug: is_youtube? ? youtube_id : URI.parse(url).path.split("/").last.split(".").first)
  end

  private

  def set_youtube_metadata #: void
    self.slug = youtube_id
    self.url = "https://www.youtube.com/watch?v=#{youtube_id}" # 정규화
    video = Yt::Video.new id: youtube_id
    self.published_at = video.published_at if video&.published_at.is_a?(Time)
    self.title = video.title if video&.title.is_a?(String)
  rescue Yt::Error => e # Yt 라이브러리 관련 오류 처리
    logger.error "YouTube API error for video ID #{youtube_id}: #{e.message}"
    # 필요하다면 title, published_at을 nil 또는 기본값으로 설정
  end

  #: (String body) -> void
  def set_webpage_metadata(body)
    self.slug = URI.parse(url)&.path.split("/").last.split(".").first
    self.published_at = url_to_published_at || parse_to_published_at(body) || Time.zone.now
    doc = Nokogiri::HTML(body)
    temp_title = doc.at("title")&.text
    self.title = temp_title if temp_title.is_a?(String)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for webpage metadata: #{url}"
    # slug, published_at, title 등에 대한 기본값 설정 또는 오류 처리
  end

  #: (Faraday::Response response) -> void
  def handle_redirection(response)
    return unless response.status.between?(300, 399) && response.headers["location"]

    # 3xx 응답인 경우 리다이렉트된 URL을 사용
    redirect_url = response.headers["location"]
    self.url = if redirect_url.start_with?("http")
                 redirect_url
    else
                 URI.join(url, redirect_url).to_s
    end
  end

  def fetch_url_content #: Faraday::Response?
    Faraday.get(url)
  rescue Faraday::Error => e
    logger.error "Error fetching URL #{url}: #{e.message}"
    nil
  end

  def url_to_published_at #: DateTime?
    match_data = URI.parse(url).path.match(%r{(\d{4})[/-](\d{2})[/-](\d{2})})
    return unless match_data

    Time.zone.parse("#{match_data[1]}-#{match_data[2]}-#{match_data[3]}")
  end

  def parse_to_published_at(body) #: DateTime?
    match_data = body.strip.match(/([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})/)
    return unless match_data

    Time.zone.parse("#{match_data[3]}-#{match_data[1]}-#{match_data[2]}")
  rescue StandardError => e
    puts "Error parsing published_at: #{e.message}"
    nil
  end
end
