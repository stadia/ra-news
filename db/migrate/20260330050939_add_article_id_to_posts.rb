class AddArticleIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :article_id, :bigint, null: true
    add_index :posts, :article_id
    add_foreign_key :posts, :articles

    rename_column :articles, :comments_count, :posts_count
  end
end
