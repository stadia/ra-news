module Madmin
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers
    include Authentication

    before_action :authenticate_admin_user

    def authenticate_admin_user
      redirect_to "/", status: :forbidden unless authenticated? && Current.user&.admin?
    end
  end
end
