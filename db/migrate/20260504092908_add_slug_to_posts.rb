class AddSlugToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :slug, :string, limit: 22
    add_index :posts, :slug, unique: true
  end
end
