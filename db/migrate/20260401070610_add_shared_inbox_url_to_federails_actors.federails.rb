# This migration comes from federails (originally 20260328000000)
class AddSharedInboxUrlToFederailsActors < ActiveRecord::Migration[7.2]
  def change
    add_column :federails_actors, :shared_inbox_url, :string
  end
end
