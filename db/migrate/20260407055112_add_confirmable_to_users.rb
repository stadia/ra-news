# frozen_string_literal: true

class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_index :users, :confirmation_token, unique: true

    reversible do |dir|
      dir.up do
        MigrationUser.update_all(confirmed_at: Time.current)
      end
    end
  end
end
