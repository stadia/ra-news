class ChangeSlugIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :articles, :slug, unique: true
    add_index :articles, :slug, unique: true, where: 'deleted_at IS NULL'
  end

  def down
    remove_index :articles, :slug, unique: true, where: 'deleted_at IS NULL'
    add_index :articles, :slug, unique: true
  end
end
