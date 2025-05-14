class AddOriginUriToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :origin_url, :string, null: false, default: ""
    Article.connection.execute("UPDATE articles SET origin_url = url")
    add_index :articles, :origin_url, unique: true
  end
end
