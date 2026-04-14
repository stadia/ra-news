# frozen_string_literal: true

class DropSlackTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :slack_article_deliveries
    drop_table :slack_workspaces
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
