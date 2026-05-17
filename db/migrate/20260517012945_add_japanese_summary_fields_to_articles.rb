class AddJapaneseSummaryFieldsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :summary_key_ja, :jsonb
    add_column :articles, :summary_detail_ja, :jsonb
    add_column :articles, :summary_body_ja, :text
  end
end
