class AddIsRelatedToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :is_related, :boolean, default: false, null: false
  end
end
