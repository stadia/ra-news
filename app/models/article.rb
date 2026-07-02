# frozen_string_literal: true
# rbs_inline: enabled

class Article < ApplicationRecord
  # ── Constants ────────────────────────────────────────────────────────
  TITLE_MAX_LENGTH = 200
  TITLE_OMISSION = "..."
  TITLE_BOUNDARY_MIN_RATIO = 0.6
  TITLE_BOUNDARY_PATTERN = /[\s[:punct:]、。，．！？；：·|｜-]/

  # title 이 일본어인지 판별한다. 가나(かな) 또는 한자(漢字) 포함 여부로 본다.
  # 한국어 제목에는 한자가 들어가지 않는다는 전제이며, 검색용 판별인
  # JAPANESE_KANA_REGEX 와 달리 한자까지 일본어로 취급한다.
  JAPANESE_TITLE_REGEX = /[\p{Hiragana}\p{Katakana}\p{Han}･-ﾟ]/

  # ── Extend ───────────────────────────────────────────────────────────
  extend FriendlyId
  friendly_id :slug, use: :slugged

  # ── Includes ─────────────────────────────────────────────────────────
  include PgSearch::Model
  include Discard::Model
  include Federails::DataEntity
  include FederailsLikeable
  include FederailsBoostable
  include Articles::LocalizedDisplay
  include Articles::Activitypub

  # ── Framework macros ─────────────────────────────────────────────────
  self.discard_column = :deleted_at
  acts_as_taggable_on :tags

  # SQLite는 벡터 임베딩을 지원하지 않으므로 PostgreSQL에서만 활성화
  # PostgreSQL은 컬럼 타입(halfvec)을 자동 감지하므로 type: 지정 불필요(SQLite 전용 옵션)
  has_neighbors :embedding, dimensions: 3072

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
  #   2) content LIKE(pg_bigm) — 한국어 사전이 못 잡는 일본어 가나(かな) 폴백
  #
  # LIKE 분기는 content 컬럼 detoast + bigm 인덱스 recheck 비용이 커서
  # (production 측정 시 150~250ms) term 에 가나가 포함된 경우에만 활성화한다.
  # 영/한 term 은 tsvector 분기만 타서 ts_rank GIN 으로 빠르게 종결.
  # LIKE 는 gin_bigm_ops 인덱스를 타지만 ILIKE 는 타지 않으므로 LIKE 를 사용한다.
  JAPANESE_KANA_REGEX = /[\p{Hiragana}\p{Katakana}･-ﾟ]/

  scope :full_text_search_for, ->(term) do
    term = term.to_s.strip
    next none if term.blank?

    tsquery = "websearch_to_tsquery('korean', #{connection.quote(term)})"
    where_clause =
      if term.match?(JAPANESE_KANA_REGEX)
        like = connection.quote("%#{sanitize_sql_like(term)}%")
        "pg_search_documents.tsvector_content_tsearch @@ #{tsquery} " \
          "OR pg_search_documents.content LIKE #{like}"
      else
        "pg_search_documents.tsvector_content_tsearch @@ #{tsquery}"
      end

    joins(:pg_search_document)
      .where(where_clause)
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

  # title 이 일본어(가나 또는 한자 포함)인 경우 title_ja 에도 함께 저장한다.
  # 판별 기준은 JAPANESE_TITLE_REGEX 를 사용한다.
  before_save :assign_japanese_title

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

  # #: () -> String
  def to_markdown
    [
      "# #{display_title}\n",
      "- **#{I18n.t('articles.markdown.source_url')}**: #{url}",
      "- **#{I18n.t('articles.markdown.ruby_news_url')}**: #{Rails.application.routes.url_helpers.article_url(self)}",
      (published_at.present? ? "- **#{I18n.t('articles.markdown.published_at')}**: #{published_at}" : nil),
      (display_summary_key.present? ? "\n## #{I18n.t('articles.markdown.summary_heading')}\n#{display_summary_key.map { |item| "- #{item}" }.join("\n")}" : nil),
      (display_summary_detail.is_a?(Hash) && display_summary_detail["introduction"].present? ? "\n## #{I18n.t('articles.markdown.introduction_heading')}\n#{display_summary_detail['introduction']}" : nil),
      (display_summary_body.present? ? "\n## #{I18n.t('articles.markdown.body_heading')}\n#{display_summary_body}" : nil),
      (display_summary_detail.is_a?(Hash) && display_summary_detail["conclusion"].present? ? "\n## #{I18n.t('articles.markdown.conclusion_heading')}\n#{display_summary_detail['conclusion']}" : nil)
    ].compact.join("\n")
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
    summary = summary_key&.first.presence || I18n.t("articles.default_summary")
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

  #: () -> Integer
  def boosts_count
    boosters_count.to_i
  end

  # slug로 Article을 찾는 메서드
  #: (String slug) -> Article?
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  # ── Private Instance Methods ─────────────────────────────────────────
  private

  #: () -> void
  def assign_japanese_title
    return if title.blank?
    return unless title.match?(JAPANESE_TITLE_REGEX)

    self.title_ja = title
  end

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
