class BackfillAdminRole < ActiveRecord::Migration[8.0]
  class MigrationRole < ApplicationRecord
    self.table_name = "roles"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    admin_role = MigrationRole.find_or_create_by!(name: "admin")
    MigrationUser.where(email_address: "admin@example.com").find_each do |user|
      user.roles = [ admin_role.name ]
      user.save
    end
  end

  def down
    admin_role = MigrationRole.find_by(name: "admin")
    return unless admin_role

    MigrationUser.where(email_address: "admin@example.com").find_each do |user|
      user.roles = []
      user.save
    end
    MigrationUser.where("'admin' = ANY (roles)").each do |user|
      user.update(roles: [ 'user' ])
    end
  end
end
