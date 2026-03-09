require "federails/data_transformer/note"

Federails.config_from "federails"

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end
end
