# frozen_string_literal: true
# rbs_inline: enabled

class SlackWorkspace < ApplicationRecord
  has_many :slack_article_deliveries, dependent: :destroy

  enum :status, {
    active: "active",
    inactive: "inactive",
    error: "error"
  }, default: :active, validate: true

  validates :team_id, :team_name, :incoming_webhook_url, :channel_id, :channel_name, presence: true
  validates :team_id, uniqueness: true

  scope :active, -> { where(status: :active) }
  scope :delivery_ready, -> {
    active.where.not(incoming_webhook_url: [ nil, "" ], channel_id: [ nil, "" ], channel_name: [ nil, "" ])
  }
end
