class CreateRolesAndUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true

    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      add_column :users, :roles, :string, array: true, default: [ "user" ]
    else
      add_column :users, :roles, :json, default: [ "user" ]
    end
  end
end
