# frozen_string_literal: true

class AddCommentsCountToArticles < ActiveRecord::Migration[8.1]
  def up
    add_column :articles, :comments_count, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE articles
      SET comments_count = comment_counts.count
      FROM (
        SELECT article_id, COUNT(*) AS count
        FROM comments
        GROUP BY article_id
      ) AS comment_counts
      WHERE articles.id = comment_counts.article_id
    SQL
  end

  def down
    remove_column :articles, :comments_count
  end
end
