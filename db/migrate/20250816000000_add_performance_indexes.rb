# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for Article queries
    add_index :articles, [:deleted_at, :published_at, :created_at], 
              name: "index_articles_on_deleted_at_and_published_at_and_created_at",
              where: "deleted_at IS NULL"
    
    # Add index for site processing jobs
    add_index :sites, [:client, :last_checked_at], 
              name: "index_sites_on_client_and_last_checked_at"
    
    # Add index for article embedding queries (vector type uses different index type)
    # Note: Vector indexes are already handled by the neighbor gem
    
    # Add index for article similarity searches
    add_index :articles, [:deleted_at, :id], 
              name: "index_articles_on_deleted_at_and_id",
              where: "deleted_at IS NULL"
              
    # Add index for comments with user association
    add_index :comments, [:article_id, :created_at, :user_id], 
              name: "index_comments_on_article_id_and_created_at_and_user_id"
  end
end