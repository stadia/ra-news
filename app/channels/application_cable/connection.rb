# frozen_string_literal: true
# rbs_inline: enabled

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      # Devise/warden, matching AuthenticatedConstraint. The Rails 8 auth
      # scaffold this replaced looked up a `Session` model that does not exist
      # in this app, so every connection raised NameError.
      def set_current_user
        warden = env["warden"]
        return false unless warden&.authenticated?(:user)

        self.current_user = warden.user(:user)
      end
  end
end
