class CreateRolesAndUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true

    add_column :users, :roles, :string, array: true, default: [ 'user' ]
  end
end
