# frozen_string_literal: true

module OauthAccounts
  module UserMatcher
    module_function

    def match_user(provider:, uid:, email:, email_verified:, relay_email:)
      oauth_account = OauthAccount.find_by(provider:, uid: uid.to_s)
      return oauth_account.user if oauth_account
      return unless email_verified
      return if relay_email
      return if email.blank?

      User.find_by(email: email.to_s.downcase)
    end
  end
end
