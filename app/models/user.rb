# frozen_string_literal: true
# rbs_inline: enabled

class User < ApplicationRecord
  AVATAR_SIZE = [ 400, 400 ].freeze
  SUPPORTED_LOCALES = %w[ko ja en].freeze
  SUPPORTED_SIGNUP_HOSTS = %w[ruby-news.dev ruby-news.jp].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :rememberable, :timeoutable, :confirmable,
         :jwt_authenticatable, :omniauthable,
         omniauth_providers: %i[google_oauth2 apple github], jwt_revocation_strategy: JwtDenylist

  has_one_attached :avatar

  has_many :push_subscriptions, dependent: :destroy

  has_many :articles, dependent: :nullify

  has_many :posts, dependent: :destroy

  has_many :refresh_tokens, dependent: :destroy

  has_many :oauth_accounts, dependent: :destroy

  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { minimum: 2, maximum: 30 },
                      format: {
                        with: /\A[a-zA-Z0-9_.]+\z/,
                        message: "영문, 숫자, 밑줄, 점만 사용할 수 있습니다"
                      }

  validates :name, length: { minimum: 2, maximum: 50 },
                   allow_blank: true
  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
  validates :signup_host, inclusion: { in: SUPPORTED_SIGNUP_HOSTS }, allow_nil: true
  validate :avatar_must_be_an_image

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :locale, with: ->(v) { v.presence }
  normalizes :signup_host, with: ->(v) { v.to_s.strip.downcase.presence }

  include Federails::ActorEntity
  acts_as_federails_actor username_field: :username, name_field: :name, profile_url_method: :user_profile_url

  after_followed :accept_follow

  after_commit :sync_federails_actor_extensions

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

    ActiveStorage::Current.url_options ||= Rails.application.routes.default_url_options.symbolize_keys
    avatar_variant.processed.url
  rescue StandardError
    nil
  end

  def remove_avatar!
    return unless avatar_attached?

    avatar.purge
    sync_federails_actor_extensions
  end

  def sync_federails_actor_extensions
    federails_actor&.update(extensions: to_activitypub_object)
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

  #: (ActiveRecord::Base likeable) -> Like
  def like!(likeable)
    actor = federails_actor or raise ArgumentError, "federails_actor is required"

    Like.create_or_find_by!(actor: actor, likeable: likeable)
  end

  #: (ActiveRecord::Base likeable) -> void
  def unlike!(likeable)
    actor = federails_actor or raise ArgumentError, "federails_actor is required"

    Like.where(actor: actor, likeable: likeable).destroy_all
  end

  #: (ActiveRecord::Base likeable) -> bool
  def likes?(likeable)
    return false unless federails_actor

    Like.exists?(actor: federails_actor, likeable: likeable)
  end

  #: (ActiveRecord::Base boostable) -> Boost
  def boost!(boostable)
    actor = federails_actor or raise ArgumentError, "federails_actor is required"

    Boost.create_or_find_by!(actor: actor, boostable: boostable)
  end

  #: (ActiveRecord::Base boostable) -> void
  def unboost!(boostable)
    actor = federails_actor or raise ArgumentError, "federails_actor is required"

    Boost.where(actor: actor, boostable: boostable).destroy_all
  end

  #: (ActiveRecord::Base boostable) -> bool
  def boosts?(boostable)
    return false unless federails_actor

    Boost.exists?(actor: federails_actor, boostable: boostable)
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
