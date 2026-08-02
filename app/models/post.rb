# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class Post < ApplicationRecord
  # ── Constants ────────────────────────────────────────────────────────
  MAX_BODY_LENGTH = 1000

  # ── Extend ───────────────────────────────────────────────────────────
  extend FriendlyId
  friendly_id :random_slug, use: :slugged

  # ── Includes ─────────────────────────────────────────────────────────
  include HtmlSanitizable
  include Posts::Blog
  include Posts::Federation
  include Posts::FederationIngest
  include Discard::Model
  include Federails::DataEntity
  include FederailsLikeable
  include FederailsBoostable

  self.discard_column = :deleted_at

  # ── Framework Macros ─────────────────────────────────────────────────
  acts_as_nested_set
  acts_as_taggable_on :tags

  # ── Enums ────────────────────────────────────────────────────────────
  enum :post_type, [ :short, :blog, :comment ], default: :short
  enum :status, [ :draft, :published ], default: :published

  # ── Associations ─────────────────────────────────────────────────────
  belongs_to :user, optional: true
  belongs_to :article, optional: true, counter_cache: :posts_count
  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true

  # ── Scopes ───────────────────────────────────────────────────────────
  scope :comments, -> { where(post_type: :comment) }
  scope :standalone, -> { where(article_id: nil) }
  scope :visible, -> { where(status: :published).kept }
  scope :published_blog, -> { blog.published }

  # ── Validations ──────────────────────────────────────────────────────
  validates :body, presence: true, unless: :draft_blog?
  validates :title, presence: true, if: :published_blog?
  validates :slug, uniqueness: true, allow_nil: true
  validate :validate_user_or_actor
  validate :validate_parent_post

  # Federails::DataEntity가 추가하는 federails_actor presence 검증을 제거
  federails_actor_presence_validator = _validate_callbacks
    .map(&:filter)
    .find do |filter|
      filter.is_a?(ActiveRecord::Validations::PresenceValidator) &&
        filter.attributes == [ :federails_actor ]
    end
  skip_callback :validate, :before, federails_actor_presence_validator if federails_actor_presence_validator

  # ── Callbacks ────────────────────────────────────────────────────────
  before_validation :type_article_post_as_comment, on: :create
  after_commit :enqueue_reply_notification, on: :create
  after_commit :enqueue_article_thumbnail, on: :create

  # ── Soft delete ──────────────────────────────────────────────────────
  # Only published posts were ever federated, so only they emit Delete/Undo.
  # Drafts are local-only, so discarding/restoring one federates nothing.
  after_discard { create_federails_activity "Delete" if published? }
  after_undiscard { create_federails_activity "Undo" if published? }

  # ── Federation ───────────────────────────────────────────────────────
  acts_as_federails_data handles: "Note",
                         actor_entity_method: :federation_actor_entity,
                         soft_deleted_method: :discarded?,
                         soft_delete_date_method: :deleted_at,
                         should_federate_method: :should_federate?

  # Only blog posts support soft delete (trash/restore). Short posts and
  # comments hard-destroy, both locally and on inbound federated Delete, so
  # their rows (and counter caches) are removed as before.
  on_federails_delete_requested -> { logger.info { "Federated post deletion requested #{id}" }; blog? ? discard! : destroy! }
  on_federails_undelete_requested :undiscard!

  # ── Public Instance Methods ──────────────────────────────────────────

  #: () -> (User | Federails::Actor)?
  def federation_actor_entity
    user || federails_actor
  end

  #: () -> bool
  def should_federate?
    # Only published posts federate. Drafts must stay local — without the
    # published? gate, Federails' after_create/after_update would push an
    # unpublished draft (and every autosave) to remote followers. Discarded
    # posts keep status :published, so after_discard can still emit a Delete.
    federation_actor_entity.present? && published?
  end


  #: () -> Integer
  def likes_count
    likers_count.to_i
  end

  #: () -> Integer
  def boosts_count
    boosters_count.to_i
  end

  #: () -> (Post | Article)
  def reply
    parent.present? ? parent : article
  end

  #: () -> Array[String]
  def federation_reply_recipients
    if parent&.federails_actor&.distant?
      [ parent.federails_actor.federated_url ]
    else
      []
    end
  end

  #: () -> String
  def author_name
    user&.full_name || federails_actor&.username || "익명"
  end

  #: () -> String?
  def author_host
    return if user_id.present?
    return if federails_actor.nil? || federails_actor&.server.blank?
    "(#{federails_actor&.server})"
  end

  # ── Private Instance Methods ─────────────────────────────────────────
  private

  def create_federails_activity(action, actor: nil, to: nil, cc: nil)
    actor ||= federails_actor || user&.federails_actor
    return if actor.blank?

    # A draft never federated, so its first publish fires an "Update" (via the
    # after_update callback) that remotes would drop — there's no object to
    # update yet. Promote that first Update to a "Create" so the post is
    # actually delivered. Once a Create exists, later edits federate as Updates.
    if action == "Update" && !Federails::Activity.exists?(entity: self, action: "Create")
      action = "Create"
    end

    super(action, actor: actor, to: to, cc: cc)
  end

  # Posts attached to an article are comments and must stay in the `comments`
  # scope (post_type = :comment). The enum default is :short, so any creation
  # path that doesn't explicitly type the post (e.g. the local comment UI) would
  # otherwise leave an article-attached post as :short and drop it from the
  # comments list. We only promote the default :short here, so an explicitly
  # typed :longform or already :comment (e.g. federated reply_attributes) is
  # left untouched. Standalone posts (article_id nil) are never affected.
  #: () -> void
  def type_article_post_as_comment
    self.post_type = :comment if article_id.present? && short?
  end

  #: () -> void
  def enqueue_reply_notification
    unless parent_id.present?
      logger.debug { "ReplyNotification skip: post #{id} has no parent" }
      return
    end
    unless parent&.user_id.present?
      logger.debug { "ReplyNotification skip: parent post #{parent_id} has no local user" }
      return
    end
    if parent.user_id == user_id
      logger.debug { "ReplyNotification skip: self-reply by user #{user_id}" }
      return
    end

    logger.info { "ReplyNotification enqueue: post #{id} → parent #{parent_id} (user #{parent.user_id})" }
    ReplyNotificationJob.perform_later(parent.id, id)
  end

  #: () -> void
  def enqueue_article_thumbnail
    return unless article_id.present?
    return if article.blank?
    return if article.thumbnail.attached?

    logger.info { "ArticleThumbnail enqueue: comment on article #{article_id}" }
    ArticleThumbnailJob.perform_later(article_id)
  end

  #: () -> void
  def set_federails_actor
    return if federation_actor_entity.nil?

    super
  end

  #: () -> void
  def validate_user_or_actor
    unless user_id.present? || federails_actor_id.present?
      errors.add(:base, "user 또는 federails_actor가 필요합니다")
    end
  end

  #: () -> void
  def validate_parent_post
    return unless parent_id.present?

    if parent.nil?
      errors.add(:parent_id, "원본 포스트를 찾을 수 없습니다.")
    end
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  #: () -> String
  def random_slug
    SecureRandom.urlsafe_base64(16)
  end
end
