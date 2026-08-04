# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class GoogleOauth < OauthBase
    preference_key "google_oauth"

    pref :client_id, env: "GOOGLE_OAUTH_CLIENT_ID"
    pref :client_secret, env: "GOOGLE_OAUTH_CLIENT_SECRET"

    def self.configured?
      client_id.present? && client_secret.present?
    end
  end
end
