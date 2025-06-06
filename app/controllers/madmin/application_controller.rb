module Madmin
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers
    include Authentication

    before_action :authenticate_admin_user

    def authenticate_admin_user
      redirect_to "/", status: :not_found unless authenticated? && Current.user.email_address == "stadia@gmail.com"
    end
  end
end
