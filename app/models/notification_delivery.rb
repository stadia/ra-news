# typed: strong
# frozen_string_literal: true
# rbs_inline: enabled

class NotificationDelivery < ApplicationRecord
  belongs_to :article
  belongs_to :notification_channel

  enum :status, {
    sent: "sent",
    failed: "failed"
  }, default: :failed, validate: true

  validates :channel_id, :channel_name, presence: true
  validates :article_id, uniqueness: { scope: [ :notification_channel_id, :channel_id ] }
end
