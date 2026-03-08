# frozen_string_literal: true

# rbs_inline: enabled

class Comment < ApplicationRecord
  acts_as_nested_set

  MAX_BODY_LENGTH = 1000
  MAX_GUEST_NAME_LENGTH = 100

  belongs_to :user, optional: true
  belongs_to :article, counter_cache: true

  has_secure_password :guest_password, validations: false

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }
  validates :article, presence: true
  validates :guest_name,
    length: { maximum: MAX_GUEST_NAME_LENGTH },
    format: { with: /\A[^<>]*\z/, message: "HTML 태그를 포함할 수 없습니다" },
    if: :guest?
  validate :validate_user_or_guest
  validate :validate_parent_comment
  validate :validate_guest_password_length
  after_commit :enqueue_reply_notification, on: :create

  include Federails::DataEntity

  acts_as_federails_data handles: "Note", actor_entity_method: :user

  on_federails_delete_requested -> { logger.info { "Deletion requested" } }

  def to_activitypub_object
    Federails::DataTransformer::Note.to_federation self, content: body
  end

  def self.from_activitypub_object(hash)
    {
      federated_url: hash["id"],
      body: hash["content"]
    }
  end

  def content
    body
  end

  def author_name
    user&.name || guest_name || "익명"
  end

  def guest?
    user_id.nil?
  end

  private

  def validate_user_or_guest
    if user_id.nil?
      # Guest comment requires guest_name AND guest_password
      if guest_name.blank?
        errors.add(:guest_name, "이름을 입력해주세요")
      end

      # Check if password is set (either as a virtual attribute for new records or digest for existing)
      unless guest_password_digest.present? || guest_password.present?
        errors.add(:guest_password, "비밀번호를 입력해주세요")
      end
    end
  end


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

  def validate_guest_password_length
    # Only validate password length when a new password is being set (not for existing records with digest)
    if guest? && guest_password.present? && guest_password.length < 4
      errors.add(:guest_password, "비밀번호는 최소 4자 이상이어야 합니다")
    end
  end

  def enqueue_reply_notification
    return unless parent_id.present?
    return unless parent&.user_id.present?
    return if parent.user_id == user_id

    ReplyNotificationJob.perform_later(parent.id, id)
  end
end
