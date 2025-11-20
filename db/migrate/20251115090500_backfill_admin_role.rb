class BackfillAdminRole < ActiveRecord::Migration[8.0]
  class MigrationRole < ApplicationRecord
    self.table_name = "roles"
  end

  class MigrationUserRole < ApplicationRecord
    self.table_name = "user_roles"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    admin_role = MigrationRole.find_or_create_by!(name: "admin")

    MigrationUser.where(email_address: "stadia@gmail.com").find_each do |user|
      MigrationUserRole.find_or_create_by!(user_id: user.id, role_id: admin_role.id)
    end
  end

  def down
    admin_role = MigrationRole.find_by(name: "admin")
    return unless admin_role

    MigrationUserRole.where(role_id: admin_role.id).delete_all
    admin_role.destroy!
  end
end
