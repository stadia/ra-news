# frozen_string_literal: true

class AddLongformStateToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :post_type, :integer, null: false, default: 0
    add_column :posts, :status, :integer, null: false, default: 1
    add_column :posts, :published_at, :datetime

    add_index :posts, [ :post_type, :status, :created_at ], name: "index_posts_on_type_status_created_at"
    add_index :posts, [ :user_id, :post_type, :status, :created_at ], name: "index_posts_on_user_type_status_created_at"

    execute <<~SQL.squish
      UPDATE posts
      SET post_type = CASE WHEN article_id IS NULL THEN 0 ELSE 2 END,
          status = 1,
          published_at = COALESCE(created_at, NOW())
    SQL
  end

  def down
    remove_index :posts, name: "index_posts_on_user_type_status_created_at"
    remove_index :posts, name: "index_posts_on_type_status_created_at"
    remove_column :posts, :published_at
    remove_column :posts, :status
    remove_column :posts, :post_type
  end
end
