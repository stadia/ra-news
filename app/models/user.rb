# frozen_string_literal: true

class User < ApplicationRecord
  AVATAR_SIZE = [ 400, 400 ].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :rememberable, :timeoutable, :confirmable

  acts_as_liker
  has_one_attached :avatar
  has_many :push_subscriptions, dependent: :destroy
  has_many :articles, dependent: :nullify
  has_many :posts, dependent: :destroy

  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { minimum: 2, maximum: 30 },
                      format: {
                        with: /\A[a-zA-Z0-9_]+\z/,
                        message: "영문, 숫자, 밑줄만 사용할 수 있습니다"
                      }

  validates :name, length: { minimum: 2, maximum: 50 },
                   allow_blank: true
  validate :avatar_must_be_an_image

  normalizes :email, with: ->(e) { e.strip.downcase }

  include Federails::ActorEntity
  acts_as_federails_actor username_field: :username, name_field: :name, profile_url_method: :user_profile_url

  after_followed :accept_follow

  scope :with_role, ->(role_name) do
    where("? = ANY (roles)", role_name.to_s)
  end
  scope :admins, -> { with_role(:admin) }

  def admin?
    has_role?(:admin)
  end

  def full_name
    name.presence || email.split("@").first
  end

  def has_role?(role_name)
    roles.include? role_name.to_s
  end

  def roles=(role_names)
    self[:roles] = role_names.is_a?(Array) ? role_names.uniq : role_names.split(" ").uniq
  end

  def accept_follow(following, follow_activity:)
    return unless has_role?(:bot)

    following.accept!(follow_activity: follow_activity)
  end

  def avatar_attached?
    avatar.attached?
  end

  def avatar_url
    return unless avatar_attached?

    Rails.application.routes.url_helpers.rails_representation_url(
      avatar_variant.processed,
      **Rails.application.routes.default_url_options.symbolize_keys
    )
  end

  def remove_avatar!
    avatar.purge if avatar_attached?
  end

  def to_activitypub_object
    return {} unless avatar_attached?

    {
      icon: {
        type: "Image",
        mediaType: avatar.blob.content_type,
        url: avatar_url
      }
    }
  end

  def self.first_bot
    with_role("bot").first
  end

  private

  def avatar_variant
    avatar.variant(resize_to_fill: AVATAR_SIZE)
  end

  def avatar_must_be_an_image
    return unless avatar_attached?
    return if avatar.blob.content_type.start_with?("image/")

    errors.add(:avatar, "이미지 파일만 업로드할 수 있습니다")
  end
end
