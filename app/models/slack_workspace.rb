# frozen_string_literal: true

class SlackWorkspace < ApplicationRecord
  has_many :user_workspace_subscriptions, dependent: :destroy
  has_many :users, through: :user_workspace_subscriptions
  has_many :slack_article_deliveries, dependent: :destroy

  enum :status, {
    active: "active",
    inactive: "inactive",
    error: "error"
  }, default: :active, validate: true

  validates :team_id, :team_name, :bot_access_token, :bot_user_id, presence: true
  validates :team_id, uniqueness: true

  scope :active, -> { where(status: :active) }
end
