class RemovePasswordDigestFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :password_digest, :string, null: false if column_exists?(:users, :password_digest)
  end
end
