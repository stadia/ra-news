class AddUsernameToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string, null: true, limit: 50
    change_column :users, :name, :string, null: false, limit: 50
  end
end
