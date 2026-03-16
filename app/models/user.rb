# frozen_string_literal: true

# rbs_inline: enabled

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :articles, dependent: :nullify

  generates_token_for :email_verification, expires_in: 24.hours do
    [email_address, email_verified_at]
  end

  before_save :clear_email_verification_on_email_change, if: :email_address_changed?

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

  # Include the concern here:
  include Federails::ActorEntity

  # Configure field names
  acts_as_federails_actor username_field: :username, name_field: :name, profile_url_method: :user_profile_url

  after_followed :accept_follow

  # Scopes
  scope :with_role, ->(role_name) do
    where("? = ANY (roles)", role_name.to_s)
  end
  scope :admins, -> { with_role(:admin) }

  def email_verified? #: bool
    email_verified_at.present?
  end

  def admin? #: bool
    has_role?(:admin)
  end

  def full_name #: String
    name.presence || email_address.split("@").first
  end

  def has_role?(role_name) #: bool
    roles.include? role_name.to_s
  end

  def roles=(role_names)
    self[:roles] = role_names.is_a?(Array) ? role_names.uniq : role_names.split(" ").uniq
  end

  def accept_follow(following)
    following.accept! if has_role?(:bot) && following.respond_to?(:accept!)
  end

  def self.first_bot
    with_role("bot").first
  end

  private

  def clear_email_verification_on_email_change
    self.email_verified_at = nil
  end
end
