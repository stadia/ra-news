# frozen_string_literal: true

# rbs_inline: enabled

module Federails
  class ApplicationController < ::ApplicationController
    helper_method :current_user

    protected
      def authenticate_user!
        current_user || request_authentication
      end

      def current_user
        Current.user
      end

      def request_authentication
        session[:return_to_after_authenticating] = request.url
        redirect_to main_app.new_session_path
      end
  end
end
