class ChangeBaseuriFromSite < ActiveRecord::Migration[8.0]
  def change
    change_column :sites, :base_uri, :string, null: true
    add_column :users, :name, :string, null: false
  end
end
