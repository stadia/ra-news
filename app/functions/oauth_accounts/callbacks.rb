# frozen_string_literal: true

module OauthAccounts
  module Callbacks
    module_function

    def handle_callback(auth:, session:)
      oauth_data = build_auth_result(auth:)
      user = UserMatcher.match_user(
        provider: oauth_data[:provider],
        uid: oauth_data[:uid],
        email: oauth_data[:email],
        email_verified: oauth_data[:email_verified],
        relay_email: oauth_data[:relay_email]
      )

      if user
        oauth_account = OauthAccount.find_or_initialize_by(provider: oauth_data[:provider], uid: oauth_data[:uid])
        oauth_account.user = user
        oauth_account.email = oauth_data[:email]
        oauth_account.email_verified = oauth_data[:email_verified]
        oauth_account.raw_info = oauth_data[:raw_info]
        oauth_account.save!

        session.delete(:oauth_signup)
        return { type: :sign_in, user: user }
      end

      session[:oauth_signup] = oauth_data.slice(:provider, :uid, :email, :email_verified, :relay_email, :name, :raw_info).deep_stringify_keys

      {
        type: :complete_signup,
        suggested_username: UsernameSuggester.suggest_username(name: oauth_data[:name], email: oauth_data[:email])
      }
    end

    def build_auth_result(auth:)
      info = auth.fetch("info", {}).with_indifferent_access
      credentials = auth.fetch("credentials", {}).with_indifferent_access
      email = info[:email].to_s.presence

      {
        provider: auth.fetch("provider"),
        uid: auth.fetch("uid").to_s,
        email:,
        email_verified: verified_email?(provider: auth.fetch("provider"), info:, credentials:),
        relay_email: relay_email?(email),
        name: info[:name].to_s.presence,
        raw_info: auth.deep_dup
      }
    end

    def relay_email?(email)
      email.to_s.downcase.ends_with?("@privaterelay.appleid.com")
    end

    def verified_email?(provider:, info:, credentials:)
      value = case provider.to_s
      when "google_oauth2"
        info[:email_verified]
      when "apple"
        info[:email_verified].nil? ? credentials[:email_verified] : info[:email_verified]
      else
        info[:email_verified] || credentials[:email_verified]
      end

      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
