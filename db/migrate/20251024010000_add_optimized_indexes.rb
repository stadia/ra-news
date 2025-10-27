# frozen_string_literal: true

class AddOptimizedIndexes < ActiveRecord::Migration[8.0]
  def up
    # Articles: Add single index for site_id (FK lookup optimization)
    # Only if not already part of a composite index being actively used
    unless index_exists?(:articles, :site_id)
      add_index :articles, :site_id
    end

    # Articles: Add index for Korean title searches
    # Useful for full-text search queries on title_ko
    unless index_exists?(:articles, :title_ko, where: "deleted_at IS NULL")
      add_index :articles, :title_ko, where: "deleted_at IS NULL"
    end

    # Comments: Add optimized index for nested_set tree traversal
    # Useful for range queries: WHERE article_id = ? AND lft BETWEEN ? AND ?
    unless index_exists?(:comments, [ :article_id, :lft, :rgt ])
      add_index :comments, [ :article_id, :lft, :rgt ]
    end

    # Preferences: Add index for preference name lookups
    # Useful for queries like: WHERE name = 'preference_name'
    unless index_exists?(:preferences, :name, where: "name IS NOT NULL")
      add_index :preferences, :name, where: "name IS NOT NULL"
    end

    # PgSearch: Add composite index for better search performance
    # Optimize searchable lookups with ordering by creation date
    unless index_exists?(:pg_search_documents, [ :searchable_type, :searchable_id, :created_at ])
      add_index :pg_search_documents, [ :searchable_type, :searchable_id, :created_at ]
    end

    # Tags: Add index for unique name constraint (if not exists)
    # Some queries might look up tags by name independently
    unless index_exists?(:tags, :name)
      add_index :tags, :name, unique: true, name: 'index_tags_on_name'
    end

    # Taggings: Add optimized index for common tagging queries
    # Query pattern: WHERE taggable_id = ? AND taggable_type = ? AND tagger_id = ? AND context = ?
    unless index_exists?(:taggings, [ :taggable_id, :taggable_type, :tagger_id, :context ])
      add_index :taggings, [ :taggable_id, :taggable_type, :tagger_id, :context ]
    end

    # Users: Add index for email lookups (likely for authentication)
    unless index_exists?(:users, :email_address)
      add_index :users, :email_address, unique: true
    end
  end

  def down
    # Remove newly added indexes
    remove_index :articles, :site_id, if_exists: true
    remove_index :articles, :title_ko, if_exists: true
    remove_index :comments, [ :article_id, :lft, :rgt ], if_exists: true
    remove_index :preferences, :name, if_exists: true
    remove_index :pg_search_documents, [ :searchable_type, :searchable_id, :created_at ], if_exists: true

    # Tags: Only remove if we added it (defensive)
    remove_index :tags, name: 'index_tags_on_name', if_exists: true

    remove_index :taggings, [ :taggable_id, :taggable_type, :tagger_id, :context ], if_exists: true
    remove_index :users, :email_address, if_exists: true
  end
end
