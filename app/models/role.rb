# frozen_string_literal: true

# rbs_inline: enabled

class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :named, ->(role_name) { where(name: role_name.to_s) }
end
