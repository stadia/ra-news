# This migration comes from federails (originally 20260328120001)
class CreateFederailsFeaturedTags < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_featured_tags do |t|
      t.references :actor, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :federails_featured_tags, [ :actor_id, :name ], unique: true
  end
end
