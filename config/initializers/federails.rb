require "fediverse/inbox"

Alba.backend = :oj

Federails.config_from "federails"

Federails.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end

Rails.application.config.after_initialize do
  Federails::Actor.acts_as_liker unless Federails::Actor.method_defined?(:like!)
end
