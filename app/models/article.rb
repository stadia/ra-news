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

  # ── Framework macros ─────────────────────────────────────────────────
  self.discard_column = :deleted_at
  acts_as_likeable
  acts_as_taggable_on :tags

  # SQLite는 벡터 임베딩을 지원하지 않으므로 PostgreSQL에서만 활성화
  has_neighbors :embedding, dimensions: 1536

  multisearchable against: [ :title, :title_ko, :summary_key, :summary_detail, :body ],
                   if: ->(record) { record.deleted_at.nil? }

  store_accessor :summary_detail, :introduction, :conclusion, prefix: :summary
  store_accessor :social_post_ids, :twitter_id, :mastodon_id

  # ── Associations ─────────────────────────────────────────────────────
  belongs_to :user
  belongs_to :site, optional: true
  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true

  has_many :posts, dependent: :nullify
  has_many :notification_deliveries, dependent: :destroy

  has_one_attached :thumbnail

  # ── Scopes ───────────────────────────────────────────────────────────
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

  before_save :log_tracked_attribute_changes, if: :tracked_attribute_changes?

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

  #: (untyped value) -> untyped
  def title=(value)
    super(self.class.truncate_title(value))
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

  #: (String action) -> void
  def create_federails_activity(action)
    ensure_federails_configuration!
    return unless local_federails_entity? && send(federails_data_configuration[:should_federate_method])

    actor = federails_actor
    return if actor.blank?

    if action == "Update"
      unless Federails::Activity.exists?(entity: self, action: "Create")
        action = "Create"
      else
        logger.info do
          {
            message: "[Federation] Skipping repeated Article update activity",
            article_id: id,
            federated_url: federated_url
          }.inspect
        end
        return
      end
    end
    Federails::Activity.create!(actor:, action:, entity: self)
  end

  #: () -> void
  def clear_rss_cache
    Rails.cache.delete("rss_articles")
  end

  def tracked_attribute_changes?
    will_save_change_to_url? ||
      will_save_change_to_origin_url? ||
      will_save_change_to_title? ||
      will_save_change_to_title_ko?
  end

  def log_tracked_attribute_changes
    changes = {}
    changes[:url] = url_change_to_be_saved if will_save_change_to_url?
    changes[:origin_url] = origin_url_change_to_be_saved if will_save_change_to_origin_url?
    changes[:title] = title_change_to_be_saved if will_save_change_to_title?
    changes[:title_ko] = title_ko_change_to_be_saved if will_save_change_to_title_ko?

    source_locations = caller_locations(1, 20)
                       .map(&:path)
                       .select { |path| path.include?("/app/") || path.include?("/lib/") || path.include?("/config/") }
                       .uniq
                       .first(6)

    logger.info do
      {
        message: "[Article] tracked attributes changing",
        article_id: id,
        persisted: persisted?,
        changes: changes,
        sources: source_locations
      }.inspect
    end
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
