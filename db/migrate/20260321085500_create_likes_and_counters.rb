# frozen_string_literal: true

class CreateLikesAndCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.string :liker_type, null: false
      t.bigint :liker_id, null: false
      t.string :likeable_type, null: false
      t.bigint :likeable_id, null: false
      t.datetime :created_at, null: false
    end

    add_index :likes, [ :liker_type, :liker_id ], name: "index_likes_on_liker"
    add_index :likes, [ :likeable_type, :likeable_id ], name: "index_likes_on_likeable"
    add_index :likes, [ :liker_type, :liker_id, :likeable_type, :likeable_id ],
      unique: true,
      name: "index_likes_on_liker_and_likeable"

    add_column :users, :likees_count, :integer, default: 0, null: false
    add_column :posts, :likers_count, :integer, default: 0, null: false
  end
end
