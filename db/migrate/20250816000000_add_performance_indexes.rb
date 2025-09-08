# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for Article queries
    add_index :articles, [ :deleted_at, :published_at, :created_at ],
              where: "deleted_at IS NULL"

    # Add index for site processing jobs
    add_index :sites, [ :client, :last_checked_at ]

    # Add index for article embedding queries (vector type uses different index type)
    # Note: Vector indexes are already handled by the neighbor gem

    # Add index for article similarity searches
    add_index :articles, [ :deleted_at, :id ],
              where: "deleted_at IS NULL"

    # Add index for comments with user association
    add_index :comments, [ :article_id, :created_at, :user_id ]
  end
end
