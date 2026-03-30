class MigrateCommentsToPosts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO posts (body, user_id, federails_actor_id, federated_url, article_id, parent_id, lft, rgt, depth, children_count, created_at, updated_at)
      SELECT body, user_id, federails_actor_id, federated_url, article_id, parent_id, lft, rgt, depth, children_count, created_at, updated_at
      FROM comments
    SQL

    execute <<~SQL
      UPDATE articles
      SET posts_count = (SELECT COUNT(*) FROM posts WHERE posts.article_id = articles.id)
    SQL

    drop_table :comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
