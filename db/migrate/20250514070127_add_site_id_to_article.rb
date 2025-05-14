class AddSiteIdToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :site_id, :bigint, null: false, default: 0
  end
end
