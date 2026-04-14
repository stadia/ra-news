# frozen_string_literal: true
# rbs_inline: enabled

class DiscordConfig
  PREFERENCE_KEY = "discord_oauth" #: String

  class << self
    #: () -> String?
    def client_id
      preference&.client_id
    end

    #: () -> String?
    def client_secret
      preference&.client_secret
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
