class RemoveIndexArticlesOnDeletedAt < ActiveRecord::Migration[8.1]
  def up
    remove_index :articles, :deleted_at, name: :index_articles_on_deleted_at
  end

  def down
    add_index :articles, :deleted_at
  end
end
