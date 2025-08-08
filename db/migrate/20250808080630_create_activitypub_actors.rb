class CreateActivitypubActors < ActiveRecord::Migration[8.0]
  def change
    create_table :activitypub_actors do |t|
      t.string :username, null: false
      t.string :domain, null: false
      t.string :display_name
      t.text :bio
      t.text :private_key, null: false
      t.text :public_key, null: false
      t.references :site, null: true, foreign_key: true
      t.timestamp :deleted_at

      t.timestamps
    end

    add_index :activitypub_actors, [:username, :domain], unique: true
    add_index :activitypub_actors, :deleted_at
  end
end