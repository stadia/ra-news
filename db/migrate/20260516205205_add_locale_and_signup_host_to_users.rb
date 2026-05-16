class AddLocaleAndSignupHostToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locale, :string, limit: 2
    add_column :users, :signup_host, :string, limit: 14
  end
end
