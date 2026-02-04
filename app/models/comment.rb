# frozen_string_literal: true

# rbs_inline: enabled

class Comment < ApplicationRecord
  acts_as_nested_set

  MAX_BODY_LENGTH = 1000

  belongs_to :user, optional: true
  belongs_to :article, counter_cache: true

  has_secure_password :guest_password, validations: false

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }
  validates :article, presence: true
  validate :validate_user_or_guest
  validate :validate_guest_password_length

  def content
    body
  end

  def author_name
    user&.name || guest_name || guest_email || "익명"
  end

  def guest?
    user_id.nil?
  end

  private

  def validate_user_or_guest
    if user_id.nil?
      # Guest comment requires (guest_name OR guest_email) AND guest_password
      if guest_name.blank? && guest_email.blank?
        errors.add(:base, "이메일 또는 이름을 입력해주세요")
      end

      # Check if password is set (either as a virtual attribute for new records or digest for existing)
      unless guest_password_digest.present? || guest_password.present?
        errors.add(:guest_password, "비밀번호를 입력해주세요")
      end
    end
  end

  def validate_guest_password_length
    # Only validate password length when a new password is being set (not for existing records with digest)
    if guest? && guest_password.present? && guest_password.length < 4
      errors.add(:guest_password, "비밀번호는 최소 4자 이상이어야 합니다")
    end
  end
end
