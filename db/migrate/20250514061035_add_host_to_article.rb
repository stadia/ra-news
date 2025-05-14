class AddHostToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :host, :string, null: true
  end
end
