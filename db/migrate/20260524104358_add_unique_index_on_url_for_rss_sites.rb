class AddUniqueIndexOnUrlForRssSites < ActiveRecord::Migration[8.1]
  def change
    add_index :sites, :url, unique: true, where: "client = 0 AND deleted_at IS NULL", name: "index_sites_unique_url_for_rss"
  end
end
