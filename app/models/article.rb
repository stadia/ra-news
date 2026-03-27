# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :slug, use: :slugged

  include PgSearch::Model

  include Discard::Model

  acts_as_likeable

  # SQLite는 벡터 임베딩을 지원하지 않으므로 PostgreSQL에서만 활성화
  has_neighbors :embedding, dimensions: 1536

  self.discard_column = :deleted_at

  multisearchable against: [ :title, :title_ko, :summary_key, :summary_detail, :body ], if: lambda { |record| record.deleted_at.nil? }

  scope :full_text_search_for, ->(term) do
    joins(:pg_search_document).merge(
      PgSearch.multisearch(term).where(searchable_type: self.name)
    )
  end

  scope :related, -> { kept.where(is_related: true) }

  scope :unrelated, -> { where(is_related: false) }

  scope :confirmed, -> { where("slug IS NOT NULL AND title_ko IS NOT NULL") }

   # TOAST 컬럼(body, summary_body, embedding) 제외 스코프
   scope :without_toast, -> {
     select(column_names - %w[body summary_body embedding])
   }

   # ID + 필수 컬럼만 선택 (Admin용)
   scope :for_admin_index, -> {
     select(:id, :title_ko, :slug, :host, :is_related, :published_at, :created_at, :updated_at)
   }

  pg_search_scope :title_matching, against: [ :title, :title_ko ], using: { tsearch: { dictionary: "korean" } }

  pg_search_scope :body_matching, against: [ :body, :summary_body ], using: { tsearch: { dictionary: "korean" } }

  belongs_to :user

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
    # 제목에 "Show HN"이 포함되어 있으면 discard 처리
    if title.present? && title.match?(/Show HN/i)
      self.deleted_at = Time.zone.now
    end
  end

  before_validation on: :create do
    self.origin_url = url if origin_url.blank?
  end

  include Federails::DataEntity

  acts_as_federails_data handles: "Note", actor_entity_method: :user, soft_deleted_method: :discarded?, soft_delete_date_method: :deleted_at, should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated article deletion requested #{id}" }; discard! }

  on_federails_undelete_requested :undiscard!

  after_discard do
    create_federails_activity "Delete"
  end

  after_undiscard do
    create_federails_activity "Undo"
  end

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    content_data = base_content
    title = content_data[:title]
    summary = content_data[:summary]

    # HTML 포맷팅으로 Mastodon에서 더 멋있게 표시
    article_url = Rails.application.routes.url_helpers.article_url(self)
    custom = { "url" => article_url }

    # 해시태그 생성 (태그가 있는 경우)
    custom["tag"] = tag_list.map { |t| { "type" => "Hashtag", "name" => "#{t}" } } if tag_list.present?

    # HTML 콘텐츠 구성
    content_parts = []
    content_parts << "<p><strong>#{title}</strong></p>"
    content_parts << "<p>#{summary}</p>"

    # 링크 추가 (짧은 텍스트로)
    link_html = "<p><a href=\"#{article_url}\">🔗 원문 보기</a></p>"
    content_parts << link_html

    full_content = content_parts.join("\n")

    Federails::DataTransformer::Note.to_federation(
      self, name: title_ko, content: full_content, custom:
    )
  end

  def generate_metadata #: void
    result = metadata_service.call(self)
    logger.debug { "Article metadata preparation failed for #{url}: #{result.failure}" } if result.failure?
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

  #: () -> String?
  def user_name
    if site.present?
      site.name
    else
      host
    end
  end

  #: () -> { title: String?, summary: String }
  def base_content
    title = title_ko.presence || self.title
    summary = summary_key&.first.presence || "새로운 Ruby 관련 글이 올라왔습니다."
    { title:, summary: }
  end

  #: () -> bool
  def should_federate?
    return false if user.blank?

    title_ko.present?
  end

  #: () -> Integer
  def likes_count
    likers_count.to_i
  end

  private

  #: (String action) -> void
  def create_federails_activity(action)
    if action == "Update" && !Federails::Activity.exists?(entity: self, action: "Create")
      action = "Create"
    end
    super(action)
  end

  #: () -> void
  def clear_rss_cache
    Rails.cache.delete("rss_articles")
  end

  #: () -> bool
  def should_generate_new_friendly_id?
    false
  end

  #: () -> String
  def random_slug
    "#{Time.zone.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4)}"
  end

  def metadata_service
    @metadata_service ||= Articles::MetadataPreparationService.new
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

    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      {
        federated_url: hash["id"],
        url: hash["url"] || hash["id"],
        title: hash["name"],
        title_ko: hash["content"]
      }
    end

    #: (Hash[String, untyped]) -> bool
    def handle_federated_object?(hash)
      # 이 메서드는 inbox로 들어온 remote object를 Article이 수신할지 결정합니다.
      # Article은 로컬 bot user가 발행하는 용도이므로, remote Note는 생성 대상으로 받지 않습니다.
      # outbound federation 여부는 should_federate?가 따로 결정합니다.
      false
    end

    # inbox 디스패치 시 Article은 수신 처리를 하지 않음.
    # handle_federated_object?가 false여도 inbox는 Article에게 디스패치하므로,
    # Article.from_activitypub_object(title: 등)가 Post에 잘못 assign되는 것을 방지한다.
    #: (untyped) -> void
    def handle_incoming_fediverse_data(_activity)
    end

    # slug로 Article을 찾는 메서드
    #: (String slug) -> Article?
    def find_by_slug(slug)
      find_by(slug: slug)
    end
  end
end
