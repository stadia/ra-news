Federails.config_from "federails"

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      Current.user
    end
  end
end
