# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout -> { Components::Layout }

  def new
    build_resource
    render Views::Users::New.new(user: resource)
  end

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      set_flash_message! :notice, :signed_up
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      render Views::Users::New.new(user: resource), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Users::Edit.new(user: resource)
  end

  def password
    render Views::Users::Password.new(user: resource)
  end

  def update
    if updating_password?
      update_user_password
    else
      update_without_password
    end
  end

  def destroy
    resource.destroy!
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    redirect_to root_path, status: :see_other, notice: "계정이 삭제되었습니다."
  end

  protected

  def after_sign_up_path_for(_resource)
    root_path
  end

  def sign_up_params
    params.expect(user: [ :email, :name, :username, :password, :password_confirmation ])
  end

  def account_update_params
    params.expect(user: [ :email, :name, :username ])
  end

  private

  def updating_password?
    user = params[:user]
    return false unless user.respond_to?(:key?)
    user.key?(:password) || user.key?(:password_confirmation) ||
      user.key?("password") || user.key?("password_confirmation")
  end

  def update_user_password
    password_params = params.expect(user: [ :current_password, :password, :password_confirmation ])
    if resource.update_with_password(password_params)
      bypass_sign_in resource
      redirect_to edit_user_registration_path, notice: t("devise.registrations.updated")
    else
      render Views::Users::Password.new(user: resource), status: :unprocessable_entity
    end
  end

  def update_without_password
    if resource.update(account_update_params)
      redirect_to edit_user_registration_path, notice: t("devise.registrations.updated")
    else
      render Views::Users::Edit.new(user: resource), status: :unprocessable_entity
    end
  end
end
