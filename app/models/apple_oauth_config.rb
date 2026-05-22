# frozen_string_literal: true
# rbs_inline: enabled

class AppleOauthConfig
  PREFERENCE_KEY = "apple_oauth" #: String

  class << self
    #: () -> String?
    def client_id
      preference&.client_id.presence || ENV["APPLE_CLIENT_ID"]
    end

    #: () -> String?
    def team_id
      preference&.team_id.presence || ENV["APPLE_TEAM_ID"]
    end

    #: () -> String?
    def key_id
      preference&.key_id.presence || ENV["APPLE_KEY_ID"]
    end

    #: () -> String?
    def private_key
      preference&.signing_secret.presence || Rails.application.credentials.dig(:apple, :private_key).presence || ENV["APPLE_PRIVATE_KEY"]
    end

    #: () -> bool
    def configured?
      client_id.present? && team_id.present? && key_id.present? && private_key.present?
    end

    private

    #: () -> Preference?
    def preference
      Preference.get_object(PREFERENCE_KEY)
    end
  end
end