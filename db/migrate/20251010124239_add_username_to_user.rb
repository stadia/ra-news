class AddUsernameToUser < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :username, :string, null: true, limit: 50
    change_column :users, :name, :string, null: false, limit: 50
  end

  def down
    remove_column :users, :username, :string, null: true, limit: 50
  end
end
