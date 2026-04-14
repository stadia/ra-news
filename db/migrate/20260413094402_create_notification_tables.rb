# frozen_string_literal: true

class CreateNotificationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_channels do |t|
      t.string :type, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_verified_at
      t.string :remote_id, null: false
      t.string :name, null: false
      t.string :webhook_url, null: false
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :notification_channels, [ :type, :remote_id ], unique: true

    create_table :notification_deliveries do |t|
      t.string :type, null: false
      t.references :article, foreign_key: true
      t.references :notification_channel, foreign_key: true
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.string :status, null: false, default: "failed"
      t.datetime :sent_at
      t.text :error_message
      t.string :message_id
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :notification_deliveries,
              [ :article_id, :notification_channel_id, :channel_id ],
              unique: true,
              name: "idx_notification_deliveries_uniqueness"
  end
end
