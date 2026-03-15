class CreateMemos < ActiveRecord::Migration[8.1]
  def change
    create_table :memos do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :deleted_at
      t.string :federated_url
      t.integer :comments_count, default: 0, null: false

      t.timestamps
    end

    add_index :memos, :deleted_at
    add_index :memos, :federated_url, unique: true
  end
end
