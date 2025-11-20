# frozen_string_literal: true

# rbs_inline: enabled

class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  validates :role_id, uniqueness: { scope: :user_id }
end
