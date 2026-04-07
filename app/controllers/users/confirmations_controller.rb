# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  layout -> { Components::Layout }

  def new
    render Views::Confirmations::New.new
  end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.of_kind?(:email, :already_confirmed)
      target_path = user_signed_in? ? root_path : new_user_session_path
      redirect_to target_path, alert: t("devise.confirmations.already_confirmed")
    elsif resource.errors.empty?
      redirect_to after_confirmation_path_for(resource_name, resource)
    else
      render Views::Confirmations::New.new, status: :unprocessable_entity
    end
  end

  protected

  def after_resend_confirmation_instructions_path_for(_resource_name)
    root_path
  end
end
