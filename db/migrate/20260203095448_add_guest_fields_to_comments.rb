class AddGuestFieldsToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :guest_name, :string
    add_column :comments, :guest_password_digest, :string

    # Make user_id nullable to allow guest comments
    change_column_null :comments, :user_id, true
  end
end
