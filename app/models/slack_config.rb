# frozen_string_literal: true
# rbs_inline: enabled

class SlackConfig
  PREFERENCE_KEY = "slack_oauth"
  INSTALL_SCOPE = "channels:read,groups:read,chat:write"

  class << self
    def client_id
      preference&.client_id
    end

    def client_secret
      preference&.client_secret
    end

    def signing_secret
      preference&.signing_secret
    end

    def configured?
      client_id.present? && client_secret.present?
    end

    def install_scope
      INSTALL_SCOPE
    end

    private

    def preference
      Preference.get_object(PREFERENCE_KEY)
    end
  end
end
