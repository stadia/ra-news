# frozen_string_literal: true

class NotificationChannelsSoftDelete < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_channels, :deleted_at, :datetime, if_not_exists: :deleted_at
    add_index :notification_channels, :deleted_at
  end
end
