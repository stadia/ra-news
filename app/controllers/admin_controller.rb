# frozen_string_literal: true

# rbs_inline: enabled

class AdminController < ApplicationController
  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to main_app.new_session_path, alert: "You are not authorized to access this page" unless Current.session&.user.email_address != "stadia@gmail.com"
  end
end
