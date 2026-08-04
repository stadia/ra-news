# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class AppleOauth < OauthBase
    preference_key "apple_oauth"

    pref :client_id, env: "APPLE_CLIENT_ID"
    pref :team_id, env: "APPLE_TEAM_ID"
    pref :key_id, env: "APPLE_KEY_ID"
    pref :private_key, pref_field: :signing_secret, credentials: %i[apple private_key], env: "APPLE_PRIVATE_KEY"

    def self.configured?
      client_id.present? && team_id.present? && key_id.present? && private_key.present?
    end
  end
end
