# frozen_string_literal: true
# rbs_inline: enabled

class SlackConfig
  PREFERENCE_KEY = "slack_oauth" #: String
  INSTALL_SCOPE = "incoming-webhook" #: String

  class << self
    #: () -> String?
    def client_id
      preference&.client_id
    end

    #: () -> String?
    def client_secret
      preference&.client_secret
    end

    #: () -> String?
    def signing_secret
      preference&.signing_secret
    end

    #: () -> bool
    def configured?
      client_id.present? && client_secret.present?
    end

    #: () -> String
    def install_scope
      INSTALL_SCOPE
    end

    private

    #: () -> Preference?
    def preference
      Preference.get_object(PREFERENCE_KEY)
    end
  end
end
