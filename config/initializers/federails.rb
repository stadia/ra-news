Federails.config_from "federails"

Federails.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end
end
