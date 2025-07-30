# frozen_string_literal: true

# rbs_inline: enabled

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Email validations
  validates :email_address, presence: true,
                           uniqueness: { case_sensitive: false },
                           format: {
                             with: URI::MailTo::EMAIL_REGEXP,
                             message: "이메일 형식이 올바르지 않습니다"
                           }

  # Name validations
  validates :name, presence: true,
                   length: { minimum: 2, maximum: 50 },
                   format: {
                     with: /\A[가-힣a-zA-Z\s]+\z/,
                     message: "한글, 영문, 공백만 사용할 수 있습니다"
                   }

  # Email normalization
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  # Scopes
  scope :admins, -> { where(email_address: [ "stadia@gmail.com" ]) }

  def admin? #: bool
    email_address == "stadia@gmail.com"
  end

  def full_name #: String
    name.presence || email_address.split("@").first
  end
end
