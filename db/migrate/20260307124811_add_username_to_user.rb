class AddUsernameToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string, null: true, limit: 30
    User.find_each { |user| user.update!(username: user.name) }
    add_index :users, :username, unique: true
  end
end
