class AddPublishedAt < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :published_at, :datetime, null: true
  end
end
