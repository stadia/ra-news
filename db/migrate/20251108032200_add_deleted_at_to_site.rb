class AddDeletedAtToSite < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :deleted_at, :datetime, null: true
    add_index :sites, :deleted_at
  end
end
