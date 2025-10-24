class AddIndexCreatedAtToArticle < ActiveRecord::Migration[8.0]
  def change
    add_index :articles, :created_at
  end
end
