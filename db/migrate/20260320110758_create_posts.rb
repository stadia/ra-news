class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :body, null: false
      t.references :user
      t.references :federails_actor
      t.string :federated_url
      t.references :parent
      t.integer :lft, null: false
      t.integer :rgt, null: false
      t.integer :depth, default: 0, null: false
      t.integer :children_count, default: 0, null: false
      t.timestamps
    end

    add_index :posts, :lft
    add_index :posts, :rgt
    add_index :posts, [ :parent_id, :created_at ]
    add_index :posts, :federated_url, unique: true
  end
end
