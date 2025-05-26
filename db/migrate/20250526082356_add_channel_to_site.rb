class AddChannelToSite < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :channel, :string, null: true
  end
end
