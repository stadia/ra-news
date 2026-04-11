# frozen_string_literal: true

class CreateSlackDeliveryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_workspaces do |t|
      t.string :team_id, null: false
      t.string :team_name, null: false
      t.string :bot_access_token, null: false
      t.string :bot_user_id, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_verified_at

      t.timestamps
    end

    add_index :slack_workspaces, :team_id, unique: true

    create_table :user_workspace_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :slack_workspace, null: false, foreign_key: true
      t.string :slack_user_id
      t.string :channel_id
      t.string :channel_name
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :user_workspace_subscriptions,
      [ :user_id, :slack_workspace_id ],
      unique: true,
      name: "index_user_workspace_subscriptions_on_user_and_workspace"

    create_table :slack_article_deliveries do |t|
      t.references :article, null: false, foreign_key: true
      t.references :slack_workspace, null: false, foreign_key: true
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.string :status, null: false, default: "sent"
      t.datetime :sent_at
      t.text :error_message
      t.string :slack_message_ts

      t.timestamps
    end

    add_index :slack_article_deliveries,
      [ :article_id, :slack_workspace_id, :channel_id ],
      unique: true,
      name: "index_slack_article_deliveries_on_article_workspace_channel"
  end
end
