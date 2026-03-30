class MigrateCommentsToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :legacy_comment_id, :bigint, null: true

    execute <<~SQL
      INSERT INTO posts (body, user_id, federails_actor_id, federated_url, article_id, parent_id, legacy_comment_id, lft, rgt, depth, children_count, created_at, updated_at)
      SELECT body, user_id, federails_actor_id, federated_url, article_id, parent_id, id, lft, rgt, depth, children_count, created_at, updated_at
      FROM comments
    SQL

    execute <<~SQL
      UPDATE posts child_posts
      SET parent_id = parent_posts.id
      FROM posts parent_posts
      WHERE child_posts.legacy_comment_id IS NOT NULL
        AND child_posts.parent_id IS NOT NULL
        AND parent_posts.legacy_comment_id = child_posts.parent_id
    SQL

    execute <<~SQL
      UPDATE articles
      SET posts_count = (SELECT COUNT(*) FROM posts WHERE posts.article_id = articles.id)
    SQL

    remove_column :posts, :legacy_comment_id, :bigint

    drop_table :comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
