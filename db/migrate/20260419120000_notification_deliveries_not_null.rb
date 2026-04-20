# frozen_string_literal: true

class NotificationDeliveriesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notification_deliveries, :article_id, false
    change_column_null :notification_deliveries, :notification_channel_id, false
  end
end
