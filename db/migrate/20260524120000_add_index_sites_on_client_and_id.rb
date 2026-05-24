class AddIndexSitesOnClientAndId < ActiveRecord::Migration[8.1]
  def change
    add_index :sites, [ :client, :id ], name: "index_sites_on_client_and_id"
  end
end
