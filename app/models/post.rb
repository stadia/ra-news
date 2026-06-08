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
  include Posts::Longform
  include Federails::DataEntity
  include FederailsLikeable
  include FederailsBoostable

  # ── Framework Macros ─────────────────────────────────────────────────
  acts_as_nested_set
  acts_as_taggable_on :tags

  # ── Enums ────────────────────────────────────────────────────────────
  enum :post_type, [ :short, :longform, :comment ], default: :short
  enum :status, [ :draft, :published, :discarded ], default: :published

  # ── Associations ─────────────────────────────────────────────────────
  belongs_to :user, optional: true
  belongs_to :article, optional: true, counter_cache: :posts_count
  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true

  # ── Scopes ───────────────────────────────────────────────────────────
  scope :comments, -> { where(post_type: :comment) }
  scope :standalone, -> { where(article_id: nil) }
  scope :visible, -> { where(status: :published) }
  scope :published_longform, -> { longform.published }

  # ── Validations ──────────────────────────────────────────────────────
  validates :body, presence: true, unless: :draft_longform?
  validates :title, presence: true, if: :published_longform?
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
  after_commit :enqueue_reply_notification, on: :create
  after_commit :enqueue_article_thumbnail, on: :create

  # ── Federation ───────────────────────────────────────────────────────
  acts_as_federails_data handles: "Note",
                         actor_entity_method: :federation_actor_entity,
                         should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated post deletion requested #{id}" }; destroy! }

  # ── Public Instance Methods ──────────────────────────────────────────

  #: () -> (User | Federails::Actor)?
  def federation_actor_entity
    user || federails_actor
  end

  #: () -> bool
  def should_federate?
    federation_actor_entity.present?
  end

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    custom = {}
    if parent.present?
      custom["inReplyTo"] = parent.federated_url || Rails.application.routes.url_helpers.post_url(parent)
    elsif article.present?
      custom["inReplyTo"] = article.federated_url || Rails.application.routes.url_helpers.article_url(article)
    end

    if tag_list.any?
      custom["tag"] = tag_list.map do |name|
        { "type" => "Hashtag", "name" => "##{name}", "href" => "#{Rails.application.routes.default_url_options[:host]}/tags/#{name}" }
      end
    end

    if media_attachments.any?
      custom["attachment"] = media_attachments
    end

    content = body

    if longform?
      content = longform_summary
      custom["url"] = Rails.application.routes.url_helpers.post_url(self)
      custom["name"] = title
      custom["updated"] = updated_at.iso8601
    end

    Federails::DataTransformer::Note.to_federation(self, content: content, custom: custom)
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

    super(action, actor: actor, to: to, cc: cc)
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

  # ── Class Methods ────────────────────────────────────────────────────
  class << self
    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s
      attachments = Array.wrap(hash["attachment"]).select { |a| a.is_a?(Hash) && (a["type"] == "Document" || a["type"] == "Image") }

      object = {
        federated_url: hash["id"],
        url: hash["url"],
        title: hash["summary"].presence,
        body: extract_body_from_activitypub_object(hash, attachments:)
      }

      if in_reply_to.present?
        article_id = in_reply_to[%r{/articles/(\d+)}, 1]
        post_id = in_reply_to[%r{/posts/(\d+)}, 1]

        if article_id.present?
          object[:article_id] = article_id
        elsif post_id.present?
          object[:parent_id] = post_id
          object[:article_id] = Post.where(id: post_id).pick(:article_id)
        else
          parent = Post.find_by(federated_url: in_reply_to)
          if parent
            object[:parent_id] = parent.id
            object[:article_id] = parent.article_id
          end
        end
      end

      # Mastodon 이미지 첨부 파싱
      object[:media_attachments] = attachments.map do |a|
        { "url" => a["url"], "mediaType" => a["mediaType"], "name" => a["name"] }.compact
      end

      # Mastodon 해시태그 파싱
      hashtags = Array.wrap(hash["tag"]).select { |t| t.is_a?(Hash) && t["type"] == "Hashtag" }
      object[:tag_list] = hashtags.map { |t| t["name"].to_s.delete_prefix("#") }.uniq.join(", ") if hashtags.any?

      object
    end

    private

    #: (Hash[String, untyped], attachments: Array[Hash[String, untyped]]) -> String
    def extract_body_from_activitypub_object(hash, attachments:)
      localized_content = hash["contentMap"]
        .then { |content_map| content_map.is_a?(Hash) ? content_map.values : [] }
        .filter_map { |value| value.to_s.squish.presence }
        .first

      body = localized_content || hash["content"].to_s.squish.presence || hash["summary"].to_s.squish.presence
      return body if body.present?

      attachment_names = attachments.filter_map { |attachment| attachment["name"].to_s.squish.presence }
      attachment_names.join(" · ").presence || I18n.t("posts.remote_attachment_only_body")
    end

    #: (Hash[String, untyped]) -> bool
    def handle_federated_object?(hash)
      in_reply_to = hash["inReplyTo"].to_s

      # inReplyTo가 없으면 원문 → 수락
      return true if in_reply_to.blank?

      # inReplyTo가 로컬 post 또는 article을 가리키면 수락
      local_host = Rails.application.routes.default_url_options[:host]
      if local_host.present? && in_reply_to.include?(local_host)
        return true if in_reply_to.include?("/posts/") || in_reply_to.include?("/articles/")
      end

      # inReplyTo가 기존 post의 federated_url이면 수락
      Post.exists?(federated_url: in_reply_to)
    end
  end
end
