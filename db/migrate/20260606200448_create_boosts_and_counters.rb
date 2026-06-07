# frozen_string_literal: true

class CreateBoostsAndCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :boosts do |t|
      t.references :actor, null: false, foreign_key: { to_table: :federails_actors }
      t.string  :boostable_type, null: false
      t.bigint  :boostable_id,   null: false
      t.datetime :created_at,    null: false
    end

    add_index :boosts, [ :actor_id, :boostable_type, :boostable_id ],
              unique: true, name: "index_boosts_on_actor_and_boostable"
    add_index :boosts, [ :boostable_type, :boostable_id ],
              name: "index_boosts_on_boostable"

    add_column :federails_actors, :boostees_count, :integer, default: 0, null: false
    add_column :articles,         :boosters_count, :integer, default: 0, null: false
    add_column :posts,            :boosters_count, :integer, default: 0, null: false
  end
end
