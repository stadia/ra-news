class CreateOauthAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.boolean :email_verified, null: false, default: false
      t.jsonb :raw_info, null: false, default: {}

      t.timestamps
    end

    add_index :oauth_accounts, [ :provider, :uid ], unique: true
    add_index :oauth_accounts, [ :user_id, :provider ], unique: true
  end
end
