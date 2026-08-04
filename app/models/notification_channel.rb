# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

class NotificationChannel < ApplicationRecord
  include Discard::Model
  self.discard_column = :deleted_at

  has_many :notification_deliveries, dependent: :restrict_with_error

  enum :status, {
    active: "active",
    inactive: "inactive",
    error: "error"
  }, default: :active, validate: true

  validates :remote_id, :name, :webhook_url, :channel_id, :channel_name, presence: true
  validates :remote_id, uniqueness: { scope: :type }

  scope :active, -> { kept.where(status: :active) }
  scope :delivery_ready, -> {
    active.where.not(webhook_url: [ nil, "" ]).where.not(channel_id: [ nil, "" ]).where.not(channel_name: [ nil, "" ])
  }
end
