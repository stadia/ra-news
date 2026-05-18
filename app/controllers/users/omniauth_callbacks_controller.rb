# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout -> { Components::Layout }

  def google_oauth2
    handle_oauth_callback
  end

  def apple
    handle_oauth_callback
  end

  private

  def handle_oauth_callback
    result = OauthAccounts::Callbacks.handle_callback(auth: request.env["omniauth.auth"], session: session)

    case result[:type]
    when :sign_in
      sign_in(resource_name, result[:user])
      redirect_to root_path, notice: t("devise.omniauth_callbacks.success", kind: provider_name)
    when :complete_signup
      redirect_to new_user_oauth_registration_path
    else
      redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.failure", kind: provider_name, reason: "OAuth 인증 처리 실패")
    end
  rescue KeyError, ActiveRecord::RecordInvalid => e
    redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.failure", kind: provider_name, reason: e.message)
  end

  def provider_name
    request.env.dig("omniauth.auth", "provider").to_s.humanize.presence || "OAuth"
  end
end
