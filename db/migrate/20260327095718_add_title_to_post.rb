class AddTitleToPost < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title, :string, null: true, limit: 255
  end
end
