# frozen_string_literal: true
# rbs_inline: enabled

class UserSerializer
  include Alba::Resource
  T.unsafe(self).include(Rails.application.routes.url_helpers)

  attributes :id, :email, :name, :username, :unconfirmed_email,
             :confirmed_at, :likees_count, :created_at, :updated_at

  attribute :avatar_url do |user|
    user.avatar.attached? ? Rails.application.routes.url_helpers.url_for(user.avatar) : nil
  end
end
