# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :rememberable, :timeoutable, :confirmable

  acts_as_liker
  has_many :push_subscriptions, dependent: :destroy
  has_many :articles, dependent: :nullify
  has_many :posts, dependent: :destroy
  has_many :workspace_subscriptions, class_name: "WorkspaceSubscription", dependent: :destroy
  has_many :slack_workspaces, through: :workspace_subscriptions

  validates :username, presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { minimum: 2, maximum: 30 },
                      format: {
                        with: /\A[a-zA-Z0-9_]+\z/,
                        message: "영문, 숫자, 밑줄만 사용할 수 있습니다"
                      }

  validates :name, length: { minimum: 2, maximum: 50 },
                   allow_blank: true

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

  def accept_follow(following)
    following.accept! if has_role?(:bot) && following.respond_to?(:accept!)
  end

  def self.first_bot
    with_role("bot").first
  end
end
