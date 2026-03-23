# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout -> { Components::Layout }

  def new
    render Views::Passwords::New.new
  end

  def edit
    render Views::Passwords::Edit.new(token: params[:reset_password_token])
  end
end
