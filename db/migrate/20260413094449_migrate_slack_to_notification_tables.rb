# frozen_string_literal: true

class MigrateSlackToNotificationTables < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO notification_channels (type, status, last_verified_at, remote_id, name, webhook_url, channel_id, channel_name, metadata, created_at, updated_at)
      SELECT 'SlackChannel', status, last_verified_at, team_id, team_name, incoming_webhook_url, channel_id, channel_name, '{}', created_at, updated_at
      FROM slack_workspaces
      WHERE incoming_webhook_url IS NOT NULL AND channel_id IS NOT NULL AND channel_name IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL

    execute <<~SQL
      INSERT INTO notification_deliveries (type, article_id, notification_channel_id, channel_id, channel_name, status, sent_at, error_message, message_id, metadata, created_at, updated_at)
      SELECT 'SlackDelivery', sad.article_id, nc.id, sad.channel_id, sad.channel_name, sad.status, sad.sent_at, sad.error_message, sad.slack_message_ts, '{}', sad.created_at, sad.updated_at
      FROM slack_article_deliveries sad
      JOIN notification_channels nc ON nc.remote_id = (
        SELECT team_id FROM slack_workspaces WHERE id = sad.slack_workspace_id
      )
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    execute "DELETE FROM notification_deliveries WHERE type = 'SlackDelivery'"
    execute "DELETE FROM notification_channels WHERE type = 'SlackChannel'"
  end
end
