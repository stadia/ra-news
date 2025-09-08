class AddTitleIndexToArticle < ActiveRecord::Migration[8.0]
  def change
    unless Rails.env.test?
      add_index :articles, :title, using: :gin, opclass: :gin_bigm_ops
      add_index :articles, :title_ko, using: :gin, opclass: :gin_bigm_ops
    end
  end
end
