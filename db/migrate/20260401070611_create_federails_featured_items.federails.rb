# This migration comes from federails (originally 20260328120000)
class CreateFederailsFeaturedItems < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_featured_items do |t|
      t.references :actor, null: false
      t.string :federated_url, null: false
      t.timestamps
    end
    add_index :federails_featured_items, [ :actor_id, :federated_url ], unique: true
  end
end
