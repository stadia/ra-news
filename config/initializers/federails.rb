require "fediverse/inbox"

Federails.config_from "federails"

Federails.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end

Rails.application.config.after_initialize do
  Federails::Actor.acts_as_liker unless Federails::Actor.method_defined?(:like!)
  Fediverse::Inbox.register_handler "Like", "Note", ActivityPub::Handlers::LikeHandler, :handle_like
  Fediverse::Inbox.register_handler "Undo", "Like", ActivityPub::Handlers::LikeHandler, :handle_undo_like

  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end
end
