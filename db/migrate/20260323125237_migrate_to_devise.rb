class MigrateToDevise < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :email_address, :email
    rename_column :users, :password_digest, :encrypted_password

    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime

    unless index_exists?(:users, :email, unique: true)
      add_index :users, :email, unique: true
    end
    add_index :users, :reset_password_token, unique: true

    remove_foreign_key :sessions, :users if foreign_key_exists?(:sessions, :users)
    drop_table :sessions
  end

  def down
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    remove_index :users, :reset_password_token
    remove_column :users, :remember_created_at
    remove_column :users, :reset_password_sent_at
    remove_column :users, :reset_password_token

    rename_column :users, :encrypted_password, :password_digest
    rename_column :users, :email, :email_address
  end
end
