# frozen_string_literal: true
# rbs_inline: enabled

class OauthAccount < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :email_verified, inclusion: { in: [ true, false ] }
end
