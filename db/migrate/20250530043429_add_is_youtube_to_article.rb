class AddIsYoutubeToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :is_youtube, :boolean, default: false, null: false
  end
end
