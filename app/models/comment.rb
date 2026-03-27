# frozen_string_literal: true

# rbs_inline: enabled

class Comment < ApplicationRecord
  acts_as_nested_set

  MAX_BODY_LENGTH = 1000

  belongs_to :user, optional: true
  belongs_to :article, counter_cache: true

  include HtmlSanitizable

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }
  validates :article, presence: true
  validate :validate_user_or_actor
  validate :validate_parent_comment
  after_commit :enqueue_reply_notification, on: :create

  include Federails::DataEntity

  belongs_to :federails_actor, class_name: "Federails::Actor", optional: true
  federails_actor_presence_validator = _validate_callbacks
    .map(&:filter)
    .find do |filter|
      filter.is_a?(ActiveRecord::Validations::PresenceValidator) &&
        filter.attributes == [ :federails_actor ]
    end
  skip_callback :validate, :before, federails_actor_presence_validator if federails_actor_presence_validator

  acts_as_federails_data handles: "Note",
    actor_entity_method: :federation_actor_entity,
    should_federate_method: :should_federate?

  on_federails_delete_requested -> { logger.info { "Federated comment deletion requested #{id}" }; destroy! }

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    Federails::DataTransformer::Note.to_federation self, content: body, custom: { "inReplyTo" => reply.federated_url }
  end

  #: () -> String
  def content
    body
  end

  #: () -> String
  def author_name
    user&.name || federails_actor&.username || "익명"
  end

  #: () -> String?
  def author_host
    return if federails_actor.nil? || federails_actor&.server.blank?

    "(#{federails_actor&.server})"
  end

  #: () -> (User | Federails::Actor)?
  def federation_actor_entity
    user || federails_actor
  end

  #: () -> bool
  def should_federate?
    federation_actor_entity.present?
  end

  #: () -> (Comment | Article)
  def reply
    parent.present? ? parent : article
  end

  private

  #: () -> void
  def validate_user_or_actor
    return if user_id.present? || federails_actor_id.present?

    errors.add(:base, "user 또는 federails_actor가 필요합니다")
  end

  #: () -> void
  def set_federails_actor
    return if federation_actor_entity.nil?

    super
  end

  #: () -> void
  def validate_parent_comment
    return unless parent_id.present?

    # `parent`는 `acts_as_nested_set` gem이 제공하는 association입니다.
    # 이를 직접 사용하면 코드가 더 명확해지고 Rails의 캐싱 기능을 활용할 수 있습니다.
    if parent.nil?
      errors.add(:parent_id, "원본 댓글을 찾을 수 없습니다.")
    elsif parent.article_id != article_id
      errors.add(:parent_id, "원본 댓글이 다른 게시글에 속해 있습니다.")
    elsif parent.parent_id.present?
      errors.add(:parent_id, "대댓글에는 답글을 달 수 없습니다.")
    end
  end

  #: () -> void
  def enqueue_reply_notification
    unless parent_id.present?
      logger.debug { "ReplyNotification skip: comment #{id} has no parent" }
      return
    end
    unless parent&.user_id.present?
      logger.debug { "ReplyNotification skip: parent comment #{parent_id} has no local user" }
      return
    end
    if parent.user_id == user_id
      logger.debug { "ReplyNotification skip: self-reply by user #{user_id}" }
      return
    end

    logger.info { "ReplyNotification enqueue: comment #{id} → parent #{parent_id} (user #{parent.user_id})" }
    ReplyNotificationJob.perform_later(parent.id, id)
  end

  class << self
    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s

      article_id = in_reply_to[%r{/articles/(\d+)}, 1]
      comment_id = in_reply_to[%r{/comments/(\d+)}, 1]

      object = {
        federated_url: hash["id"],
        body: hash["content"].to_s.squish
      }

      if comment_id.present?
        parent = Comment.find_by(id: comment_id)
        if parent
          object[:parent] = parent
          article_id = parent.article_id
        end
      elsif article_id.nil?
        parent = Comment.find_by(federated_url: in_reply_to)
        if parent
          object[:parent] = parent
          article_id = parent.article_id
        end
      end
      object[:article_id] = article_id

      object
    end

    #: (Hash[String, untyped]) -> bool
    def handle_federated_object?(hash)
      in_reply_to = hash["inReplyTo"].to_s
      return false if in_reply_to.blank?

      local_host = Rails.application.routes.default_url_options[:host]
      return true if in_reply_to.include?(local_host) && !in_reply_to.include?("/posts/")

      Comment.exists?(federated_url: in_reply_to)
    end
  end
end
