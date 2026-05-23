# frozen_string_literal: true

module Configs
  class Slack < OauthBase
    INSTALL_SCOPE = "incoming-webhook"

    preference_key "slack_oauth"

    pref :client_id
    pref :client_secret
    pref :signing_secret

    def self.configured?
      client_id.present? && client_secret.present?
    end

    def self.install_scope
      INSTALL_SCOPE
    end
  end
end
