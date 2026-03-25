module Madmin
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers

    before_action :authenticate_admin_user

    def authenticate_admin_user
      authenticate_user!
      redirect_to "/", status: :forbidden unless current_user&.admin?
    end
  end
end
