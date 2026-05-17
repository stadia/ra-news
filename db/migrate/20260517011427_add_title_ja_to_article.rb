class AddTitleJaToArticle < ActiveRecord::Migration[8.1]
  def up
    change_column :articles, :title_ko, :string, limit: 100
    add_column :articles, :title_ja, :string, limit: 150
  end

  def down
    change_column :articles, :title_ko, :string
    remove_column :articles, :title_ja, :string, limit: 150
  end
end
