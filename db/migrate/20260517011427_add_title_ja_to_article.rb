class AddTitleJaToArticle < ActiveRecord::Migration[8.1]
  def change
    change_column :articles, :title_ko, :string, limit: 100
    add_column :articles, :title_ja, :string, limit: 150
  end
end
