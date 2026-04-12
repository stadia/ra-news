# frozen_string_literal: true
# rbs_inline: enabled

class WorkspaceSubscription < ApplicationRecord
  self.table_name = "user_workspace_subscriptions"

  belongs_to :user
  belongs_to :slack_workspace

  validates :user_id, uniqueness: { scope: :slack_workspace_id }
  validates :channel_id, :channel_name, presence: true, if: :active?

  scope :active, -> { where(active: true) }
end
