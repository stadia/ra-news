# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout -> { Components::Layout }

  before_action :verify_google_config, only: :google_oauth2
  before_action :verify_apple_config, only: :apple

  def google_oauth2
    handle_oauth_callback
  end

  def apple
    handle_oauth_callback
  end

  private

  def verify_google_config
    return if Configs::GoogleOauth.configured?

    redirect_to new_user_session_path, alert: t("users.omniauth_callbacks.not_configured", provider: "Google")
  end

  def verify_apple_config
    return if Configs::AppleOauth.configured?

    redirect_to new_user_session_path, alert: t("users.omniauth_callbacks.not_configured", provider: "Apple")
  end

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
  rescue KeyError, NoMethodError, ActiveRecord::RecordInvalid => e
    logger.warn("[OAuth callback failure] provider=#{provider_name} error=#{e.class}: #{e.message}")
    redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.failure", kind: provider_name, reason: "OAuth 인증 처리 실패")
  end

  def provider_name
    request.env.dig("omniauth.auth", "provider").to_s.humanize.presence || "OAuth"
  end
end
