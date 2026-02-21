class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.datetime :expiration_time
      t.datetime :last_sent_at
      t.datetime :last_error_at

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
