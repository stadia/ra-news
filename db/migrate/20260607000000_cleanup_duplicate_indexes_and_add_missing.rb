# frozen_string_literal: true

class CleanupDuplicateIndexesAndAddMissing < ActiveRecord::Migration[8.1]
  REDUNDANT_INDEXES = [
    [ :likes, :index_likes_on_actor_id ],
    [ :boosts, :index_boosts_on_actor_id ],
    [ :notification_deliveries, :index_notification_deliveries_on_article_id ],
    [ :oauth_accounts, :index_oauth_accounts_on_user_id ],
    [ :posts, :index_posts_on_parent_id ]
  ].freeze

  def up
    REDUNDANT_INDEXES.each do |table, name|
      remove_index table, name: name, if_exists: true
    end

    add_index :sites, :deleted_at,
              if_not_exists: true

    add_index :roles, :name,
              unique: true,
              if_not_exists: true
  end

  def down
    remove_index :roles, :name, if_exists: true
    remove_index :sites, :deleted_at, if_exists: true

    add_index :posts, :parent_id,
              name: :index_posts_on_parent_id,
              if_not_exists: true
    add_index :oauth_accounts, :user_id,
              name: :index_oauth_accounts_on_user_id,
              if_not_exists: true
    add_index :notification_deliveries, :article_id,
              name: :index_notification_deliveries_on_article_id,
              if_not_exists: true
    add_index :likes, :actor_id,
              name: :index_likes_on_actor_id,
              if_not_exists: true
    add_index :boosts, :actor_id,
              name: :index_boosts_on_actor_id,
              if_not_exists: true
  end
end
