# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout -> { Components::Layout }

  def new
    redirect_to root_url and return if user_signed_in?
    render Views::Sessions::New.new
  end

  def create
    super
  end

  def destroy
    super
  end
end
