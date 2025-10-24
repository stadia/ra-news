class AddIndexCreatedatToUser < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :created_at
  end
end
