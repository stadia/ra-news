# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :slug, use: :slugged

  include PgSearch::Model

  include Discard::Model

  # SQLite는 벡터 임베딩을 지원하지 않으므로 PostgreSQL에서만 활성화
  has_neighbors :embedding, dimensions: 1536

  self.discard_column = :deleted_at

  multisearchable against: [ :title, :title_ko, :summary_key, :summary_detail, :body ], if: lambda { |record| record.deleted_at.nil? }

  scope :full_text_search_for, ->(term) do
    joins(:pg_search_document).merge(
      PgSearch.multisearch(term).where(searchable_type: self.name)
    )
  end

  scope :related, -> { where(is_related: true) }

  scope :unrelated, -> { where(is_related: false) }

  scope :confirmed, -> { where("slug IS NOT NULL AND title_ko IS NOT NULL") }

  pg_search_scope :title_matching, against: [ :title, :title_ko ], using: { tsearch: { dictionary: "korean" } }

  pg_search_scope :body_matching, against: [ :body, :summary_body ], using: { tsearch: { dictionary: "korean" } }

  belongs_to :user, optional: true

  belongs_to :site, optional: true

  has_many :comments, dependent: :nullify

  store_accessor :summary_detail, :introduction, :conclusion, prefix: :summary

  store_accessor :social_post_ids, :twitter_id, :mastodon_id

  validates :url, :origin_url, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: true, allow_blank: true

  before_create :generate_metadata

  acts_as_taggable_on :tags

  after_discard do
    clear_rss_cache
    SocialDeleteJob.perform_later(id)
  end

  after_commit :clear_rss_cache, on: [ :create, :update, :destroy ]

  before_save do
    # published_at이 없으면 현재 시간으로 설정.
    # 단, LLM 요약 전에는 원본 URL에서 최대한 추출하는 것이 좋으므로,
    # 이 부분은 generate_metadata 내에서 처리되도록 합니다.
    self.published_at ||= Time.zone.now

    # 제목에 "Show HN"이 포함되어 있으면 discard 처리
    if title.present? && title.match?(/Show HN/i)
      self.deleted_at = Time.zone.now
    end
  end

  before_validation on: :create do
    self.origin_url = url if origin_url.blank?
  end

  # YouTube URL의 정규화된 호스트를 상수로 정의
  YOUTUBE_NORMALIZED_HOST = "www.youtube.com".freeze

  include Federails::DataEntity

  acts_as_federails_data handles: "Note", actor_entity_method: :user, soft_deleted_method: :discarded?, soft_delete_date_method: :deleted_at, should_federate_method: :ready_to_federate?

  on_federails_delete_requested :discard!

  on_federails_undelete_requested :undiscard!

  def to_activitypub_object
    content_data = base_content
    content = "#{content_data[:title]}\n\n#{content_data[:summary]}"
    link = Rails.application.routes.url_helpers.article_url(self)

    # Mastodon은 URL을 실제 길이로 계산하므로 링크 길이도 포함
    reserved_space = link.length + 2 # 공백과 줄바꿈
    available_content_length = MastodonService::MASTODON_CONFIG.character_limit - MastodonService::MASTODON_CONFIG.formatting_buffer - reserved_space
    truncated_content = content.truncate([ available_content_length, 1 ].max, omission: "...")

    Federails::DataTransformer::Note.to_federation(
      self,
      content: "#{truncated_content}\n\n#{link}"
    )
  end

  def generate_metadata #: void
    return unless url.is_a?(String)

    response = fetch_url_content
    return if response.nil?

    handle_redirection(response)

    set_initial_url_and_host # URL 및 호스트 초기 설정, 삭제 여부 판단

    if is_youtube?
      set_youtube_metadata
    else
      set_webpage_metadata(response.body)
    end

    unless slug.present?
      base = title.presence
      self.slug = base ? base.parameterize.presence || random_slug : random_slug
    end

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
    if is_youtube?
      new_slug = youtube_id
    else
      path = URI.parse(url).path
      new_slug = path&.split("/")&.last&.split(".")&.first
      new_slug = random_slug if new_slug.blank?
    end
    update(slug: new_slug)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for slug update: #{url}"
    false
  end

  def update_published_at #: bool
    response = fetch_url_content
    return false unless response

    update(published_at: _published_at(response.body))
  end

  def user_name
    return user&.name.present? ? user.name : "알 수 없음" if user.present?

    if site.present?
      site.base_uri.present? ? "#{site.name} (#{site.base_uri})" : site.name
    else
      "알 수 없음"
    end
  end

  def base_content
    title = title_ko.presence || self.title
    summary = summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    { title:, summary: }
  end

  def ready_to_federate?
    title_ko.present? && user.present?
  end

  private

  def create_federails_activity(action)
    if action == "Update" && !Federails::Activity.exists?(entity: self, action: "Create")
      action = "Create"
    end
    super(action)
  end

  def set_initial_url_and_host #: void
    parsed_url = URI.parse(url)
    if parsed_url.respond_to?(:query) && parsed_url.query
      query_params = URI.decode_www_form(parsed_url.query || "").to_h
      query_params.except!("utm_source", "utm_medium", "utm_campaign", "_bhlid", "ref", "utm_content", "utm_term", "ck_subscriber_id") if query_params.is_a?(Hash)
      query_params.except!("t", "feature", "si") if parsed_url.host&.match?(/youtube/i)
      self.url = query_params.empty? ? "#{parsed_url.scheme}://#{parsed_url.host}#{parsed_url.path}" : "#{parsed_url.scheme}://#{parsed_url.host}#{parsed_url.path}?#{query_params.map { |k, v| "#{k}=#{v}" }.join('&')}"
    end
    self.host = parsed_url.host
    self.is_youtube = true if host&.match?(/youtube/i)
    # IGNORE_HOSTS 패턴에 맞는 호스트이거나 경로가 너무 짧으면 discard
    self.deleted_at = Time.zone.now if !is_youtube && (parsed_url.path.nil? || parsed_url.path.size < 2) || Article.should_ignore_url?(parsed_url.to_s)
  rescue URI::InvalidURIError
    logger.error "Invalid URI for initial URL parsing: #{url}"
    self.deleted_at = Time.zone.now # 유효하지 않은 URL은 삭제 처리
  end

  def set_youtube_metadata #: void
    # self.url = "https://#{YOUTUBE_NORMALIZED_HOST}/watch?v=#{youtube_id}"
    video = Yt::Video.new id: youtube_id
    self.published_at = video.published_at if video&.published_at.is_a?(Time)
    self.title = video.title if video&.title.is_a?(String)
  rescue Yt::Error => e # Yt 라이브러리 관련 오류 처리
    logger.error "YouTube API error for video ID #{youtube_id}: #{e.message}"
    # 필요하다면 title, published_at을 nil 또는 기본값으로 설정
  end

  #: (String body) -> void
  def set_webpage_metadata(fetch_body)
    logger.debug "Setting webpage metadata for #{url}"
    return if deleted_at.present?

    self.published_at = _published_at(fetch_body)
    return if title.present?

    doc = Nokogiri::HTML5(fetch_body)
    temp_title = doc.at("title")&.text
    self.title = temp_title.strip.gsub(/\s+/, " ") if temp_title.is_a?(String)
    self.body = Readability::Document.new(fetch_body).content if body.blank?
  rescue URI::InvalidURIError
    logger.error "Invalid URI for webpage metadata: #{url}"
    # slug, published_at, title 등에 대한 기본값 설정 또는 오류 처리
  end

  #: (Faraday::Response response) -> void
  def handle_redirection(response, count = 0)
    return if response.nil?

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

  def clear_rss_cache
    Rails.cache.delete("rss_articles")
  end

  def should_generate_new_friendly_id?
    false
  end

  def random_slug
    "#{Time.zone.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4)}"
  end

  def _published_at(body)
    date_time = url_to_published_at || extract_published_at_from_content(body) || created_at || Time.zone.now
    date_time = created_at if date_time.future?
    date_time
  end

  class << self
    # 도메인과 서브도메인을 정확히 체크하는 클래스 메서드
    #: (String url) -> bool
    def should_ignore_url?(url)
      return true if url.blank?

      begin
        uri = URI.parse(url)
        host = uri.host&.downcase
        return true if host.blank?

        # Check for dangerous file extensions
        return true if %w[.epub .pdf .exe .zip .rar].any? { |ext| uri.path.end_with?(ext) }

        Preference.ignore_hosts.any? do |ignore_host|
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

    def from_activitypub_object(hash)
      {
        federated_url: hash["id"],
        url: hash["url"] || hash["id"],
        title: hash["name"],
        title_ko: hash["content"]
      }
    end

    def handle_federated_object?(hash)
      hash["inReplyTo"].blank?
    end

    # slug로 Article을 찾는 메서드
    def find_by_slug(slug)
      find_by(slug: slug)
    end
  end
end
