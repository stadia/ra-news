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
  end
end
