# frozen_string_literal: true
# rbs_inline: enabled

class Article < ApplicationRecord
  # ── Constants ────────────────────────────────────────────────────────
  TITLE_MAX_LENGTH = 120
  TITLE_OMISSION = "..."
  TITLE_BOUNDARY_MIN_RATIO = 0.6
  TITLE_BOUNDARY_PATTERN = /[\s[:punct:]、。，．！？；：·|｜-]/

  # ── Extend ───────────────────────────────────────────────────────────
  extend FriendlyId
  friendly_id :slug, use: :slugged

  # ── Includes ─────────────────────────────────────────────────────────
  include PgSearch::Model
  include Discard::Model
  include Federails::DataEntity
  include FederailsLikeable
  include ArticleClassMethods
  include LocalizedDisplay

  # ── Framework macros ─────────────────────────────────────────────────
  self.discard_column = :deleted_at
  acts_as_taggable_on :tags

  # SQLite는 벡터 임베딩을 지원하지 않으므로 PostgreSQL에서만 활성화
  has_neighbors :embedding, dimensions: 1536

  multisearchable against: [
    :title, :title_ko, :title_ja,
    :summary_key, :summary_key_ja,
    :summary_detail, :summary_detail_ja,
    :body, :summary_body, :summary_body_ja
  ],
                   if: ->(record) { record.deleted_at.nil? }

  store_accessor :summary_detail, :introduction, :conclusion, prefix: :summary
  store_accessor :summary_detail_ja, :introduction, :conclusion, prefix: :summary_ja
  store_accessor :social_post_ids, :twitter_id, :mastodon_id

  # ── Associations ─────────────────────────────────────────────────────
  belongs_to :user
  belongs_to :site, optional: true
  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true

  has_many :posts, dependent: :nullify
  has_many :notification_deliveries, dependent: :destroy

  has_one_attached :thumbnail

  # ── Scopes ───────────────────────────────────────────────────────────
  # 하이브리드 전문 검색:
  #   1) tsvector_content_tsearch(textsearch_ko, 'korean') — 한국어 형태소 + 한자
  #   2) content LIKE(pg_bigm) — 한국어 사전이 못 잡는 일본어 가나 등 부분 일치 폴백
  # 두 조건을 OR로 결합하고, 한국어 ts_rank를 1차 정렬(가나 전용 매치는 rank 0 →
  # created_at 최신순으로 후순위)로 사용한다.
  # LIKE는 gin_bigm_ops 인덱스를 타지만 ILIKE는 타지 않으므로 LIKE를 사용한다.
  scope :full_text_search_for, ->(term) do
    term = term.to_s.strip
    next none if term.blank?

    tsquery = "websearch_to_tsquery('korean', #{connection.quote(term)})"
    like    = connection.quote("%#{sanitize_sql_like(term)}%")

    joins(:pg_search_document)
      .where(
        "pg_search_documents.tsvector_content_tsearch @@ #{tsquery} " \
        "OR pg_search_documents.content LIKE #{like}"
      )
      .order(Arel.sql("ts_rank(pg_search_documents.tsvector_content_tsearch, #{tsquery}) DESC"), created_at: :desc)
  end
  scope :related, -> { kept.where(is_related: true) }
  scope :unrelated, -> { kept.where(is_related: false) }
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

  # ── Validations ──────────────────────────────────────────────────────
  validates :title, length: { maximum: TITLE_MAX_LENGTH }, allow_blank: true
  validates :url, :origin_url, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: true, allow_blank: true

  # ── Callbacks ────────────────────────────────────────────────────────
  before_validation on: :create do
    self.origin_url = url if origin_url.blank?
  end

  before_create :generate_metadata

  before_save do
    # 제목에 "Show HN"이 포함되어 있으면 discard 처리
    if title.present? && title.match?(/Show HN/i)
      self.deleted_at = Time.zone.now
    end
  end

  after_commit :clear_rss_cache, on: [ :create, :update, :destroy ]

  after_discard do
    clear_rss_cache
    SocialDeleteJob.perform_later(id)
    create_federails_activity "Delete"
  end

  after_undiscard do
    create_federails_activity "Undo"
  end

  # ── Federation ───────────────────────────────────────────────────────
  acts_as_federails_data handles: "Note",
                         actor_entity_method: :bot_user,
                         soft_deleted_method: :discarded?,
                         soft_delete_date_method: :deleted_at,
                         should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated article deletion requested #{id}" }; discard! }
  on_federails_undelete_requested :undiscard!

  # ── Public Instance Methods ──────────────────────────────────────────

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    content_data = base_content
    title = content_data[:title]
    summary = content_data[:summary]

    # HTML 포맷팅으로 Mastodon에서 더 멋있게 표시
    article_url = Rails.application.routes.url_helpers.article_url(self)
    # ActivityStreams 표준은 문자열 키를 사용하므로 custom 해시도 문자열 키로 통일
    custom = { "url" => article_url }

    # 해시태그 생성 (태그가 있는 경우)
    custom["tag"] = tag_list.map { |t| { "type" => "Hashtag", "name" => t } } if tag_list.present?

    # HTML 콘텐츠 구성
    content_parts = []
    content_parts << "<p><strong>#{title}</strong></p>"
    content_parts << "<p>#{summary}</p>"

    # 링크 추가 (짧은 텍스트로)
    link_html = "<p><a href=\"#{article_url}\">🔗 원문 보기</a></p>"
    content_parts << link_html

    full_content = content_parts.join("\n")

    # 썸네일 이미지 첨부
    if thumbnail.attached?
      thumb_url = Rails.application.routes.url_helpers.rails_blob_url(thumbnail, disposition: "inline")
      custom["attachment"] = [ { "type" => "Image", "mediaType" => thumbnail.blob.content_type, "url" => thumb_url } ]
    end

    Federails::DataTransformer::Note.to_federation(
      self, name: title_ko, content: full_content, custom:
    )
  end

  def generate_metadata #: void
    result = metadata_service.call(self)
    logger.debug { "Article metadata preparation failed for #{url}: #{result.failure}" } if result.failure?
  end

  #: (untyped value) -> untyped
  def title=(value)
    super(Articles::Utils.truncate_title(value))
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

  # ── Private Instance Methods ─────────────────────────────────────────
  private

  #: () -> User?
  def bot_user
    User.first_bot
  end

  #: (String action, ?actor: (Federails::Actor)?, ?to: untyped, ?cc: untyped) -> void
  def create_federails_activity(action, actor: nil, to: nil, cc: nil)
    actor ||= federails_actor || bot_user&.federails_actor
    return if actor.blank?

    if action == "Update"
      if Federails::Activity.exists?(entity: self, action: "Create")
        logger.info do
          {
            message: "[Federation] Skipping repeated Article update activity",
            article_id: id,
            federated_url: federated_url
          }.inspect
        end
        return
      end
      action = "Create"
    end

    super(action, actor: actor, to: to, cc: cc)
  end

  #: () -> void
  def clear_rss_cache
    Rails.cache.delete("rss_articles")
  end

  def should_generate_new_friendly_id? #: bool
    false
  end

  def random_slug #: String
    "#{Time.zone.now.strftime('%Y%m%d')}-#{SecureRandom.hex(4)}"
  end

  def metadata_service #: Articles::MetadataPreparationService
    @metadata_service ||= Articles::MetadataPreparationService.new
  end
end
