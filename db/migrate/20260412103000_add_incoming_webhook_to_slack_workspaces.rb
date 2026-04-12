# frozen_string_literal: true

class AddIncomingWebhookToSlackWorkspaces < ActiveRecord::Migration[8.1]
  def change
    add_column :slack_workspaces, :incoming_webhook_url, :string
    add_column :slack_workspaces, :channel_id, :string
    add_column :slack_workspaces, :channel_name, :string

    reversible do |dir|
      dir.up do
        drop_table :user_workspace_subscriptions, if_exists: true
      end

      dir.down do
        create_table :user_workspace_subscriptions, if_not_exists: true do |t|
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
          name: "index_user_workspace_subscriptions_on_user_and_workspace",
          if_not_exists: true
      end
    end
  end
end
