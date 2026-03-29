# This migration comes from federails (originally 20260328110000)
class CreateFederailsBlocks < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_blocks do |t|
      t.references :actor, null: false, foreign_key: { to_table: :federails_actors }
      t.references :target_actor, null: false, foreign_key: { to_table: :federails_actors }
      t.timestamps
    end
    add_index :federails_blocks, [:actor_id, :target_actor_id], unique: true
  end
end
