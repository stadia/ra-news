class AddArticleToMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :summary_key, :jsonb
    add_column :articles, :summary_detail, :jsonb
    add_column :articles, :title_ko, :string
  end
end
