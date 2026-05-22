# frozen_string_literal: true

module OauthAccounts
  module Callbacks
    MIN_LENGTH = 2
    MAX_LENGTH = 30

    class << self
      def handle_callback(auth:, session:)
        oauth_data = build_auth_result(auth:)
        user = match_user(
          provider: oauth_data[:provider],
          uid: oauth_data[:uid],
          email: oauth_data[:email],
          email_verified: oauth_data[:email_verified],
          relay_email: oauth_data[:relay_email]
        )

        if user
          oauth_account = OauthAccount.find_or_initialize_by(provider: oauth_data[:provider], uid: oauth_data[:uid])
          oauth_account.user = user
          oauth_account.email = oauth_data[:email].presence || oauth_account.email
          oauth_account.email_verified = oauth_data[:email_verified]
          oauth_account.raw_info = merged_raw_info(existing: oauth_account.raw_info, incoming: oauth_data[:raw_info])
          oauth_account.save!

          session.delete(:oauth_signup)
          return { type: :sign_in, user: user }
        end

        session[:oauth_signup] = oauth_data.slice(:provider, :uid, :email, :email_verified, :relay_email, :name, :raw_info).deep_stringify_keys

        {
          type: :complete_signup,
          suggested_username: suggest_username(name: oauth_data[:name], email: oauth_data[:email])
        }
      end

      def suggest_username(name:, email:)
        base = sanitize(name).presence || sanitize(email.to_s.split("@").first).presence || "user"
        base = "user#{base}" if base.length < MIN_LENGTH
        base = base.first(MAX_LENGTH)

        unique_username_for(base)
      end

      private

      def match_user(provider:, uid:, email:, email_verified:, relay_email:)
        oauth_account = OauthAccount.find_by(provider:, uid: uid.to_s)
        return oauth_account.user if oauth_account
        return unless email_verified
        return if relay_email
        return if email.blank?

        User.find_by(email: email.to_s.strip.downcase)
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
          raw_info: {
            "provider" => auth.fetch("provider"),
            "uid" => auth.fetch("uid").to_s,
            "info" => info.slice(:email, :name, :email_verified).to_h
          }
        }
      end

      def sanitize(value)
        value.to_s.downcase
             .gsub(/\s+/, "_")
             .gsub(/[^a-z0-9_.]/, "")
             .gsub(/_{2,}/, "_")
             .gsub(/\A[._]+|[._]+\z/, "")
      end

      def unique_username_for(base)
        return base unless User.exists?(username: base)

        suffix = 1
        loop do
          candidate = "#{base.first(MAX_LENGTH - suffix.to_s.length - 1)}_#{suffix}"
          return candidate unless User.exists?(username: candidate)

          suffix += 1
        end
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

      def merged_raw_info(existing:, incoming:)
        existing_info = existing.to_h.deep_stringify_keys
        incoming_info = incoming.to_h.deep_stringify_keys

        existing_info.deep_merge(incoming_info) do |_key, old_value, new_value|
          new_value.present? ? new_value : old_value
        end
      end
    end
  end
end
