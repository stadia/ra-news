class AddUrlToPost < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :url, :string, null: true, limit: 255
  end
end
