# frozen_string_literal: true

class SlackConfig
  class << self
    def client_id
      read(:client_id, "SLACK_CLIENT_ID")
    end

    def client_secret
      read(:client_secret, "SLACK_CLIENT_SECRET")
    end

    def signing_secret
      read(:signing_secret, "SLACK_SIGNING_SECRET")
    end

    def configured?
      client_id.present? && client_secret.present?
    end

    def install_scope
      "channels:read,groups:read,chat:write"
    end

    private

    def read(credential_key, env_key)
      Rails.application.credentials.dig(:slack, credential_key).presence || ENV[env_key].presence
    end
  end
end
