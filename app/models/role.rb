# frozen_string_literal: true

# rbs_inline: enabled

class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :named, ->(role_name) { where(name: role_name.to_s) }

  after_destroy :remove_role_from_users

  private

  def remove_role_from_users #: () -> void
    User.with_role(name).update_all([ "roles = array_remove(roles, ?)", name ])
  end
end
