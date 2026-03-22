# frozen_string_literal: true

class RemoveGuestFieldsFromComments < ActiveRecord::Migration[8.1]
  def change
    remove_column :comments, :guest_name, :string
    remove_column :comments, :guest_password_digest, :string
  end
end
