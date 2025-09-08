# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    # Performance indexes for Article model
    add_index :articles, :published_at
    add_index :articles, [ :site_id, :published_at ]
    add_index :articles, [ :is_related, :published_at ]
    add_index :articles, :host

    # Performance indexes for comments
    add_index :comments, [ :article_id, :created_at ]

    # Performance indexes for sites
    add_index :sites, :last_checked_at
    add_index :sites, [ :client, :last_checked_at ]
  end
end
