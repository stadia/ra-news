# frozen_string_literal: true

# rbs_inline: enabled

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def admin?
    email_address == "stadia@gmail.com"
  end
end
