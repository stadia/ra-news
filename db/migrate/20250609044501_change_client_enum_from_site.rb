class ChangeClientEnumFromSite < ActiveRecord::Migration[8.0]
  def change
    change_column :sites, :client, :integer, using: 'client::integer', default: 0, null: false
  end
end
