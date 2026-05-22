# frozen_string_literal: true
# rbs_inline: enabled

class GoogleOauthConfig
  PREFERENCE_KEY = "google_oauth2_oauth" #: String

  class << self
    #: () -> String?
    def client_id
      preference&.client_id.presence || ENV["GOOGLE_OAUTH_CLIENT_ID"]
    end

    #: () -> String?
    def client_secret
      preference&.client_secret.presence || ENV["GOOGLE_OAUTH_CLIENT_SECRET"]
    end

    #: () -> bool
    def configured?
      client_id.present? && client_secret.present?
    end

    private

    #: () -> Preference?
    def preference
      Preference.get_object(PREFERENCE_KEY)
    end
  end
end