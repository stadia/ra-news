# frozen_string_literal: true

class SlackArticleDelivery < ApplicationRecord
  belongs_to :article
  belongs_to :slack_workspace

  enum :status, {
    sent: "sent",
    failed: "failed"
  }, default: :sent, validate: true

  validates :channel_id, :channel_name, presence: true
  validates :article_id, uniqueness: { scope: [ :slack_workspace_id, :channel_id ] }
end
