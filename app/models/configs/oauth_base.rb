# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class OauthBase
    class << self
      def preference_key(key)
        const_set(:PREFERENCE_KEY, key)
      end

      def pref(name, env: nil, credentials: nil, pref_field: nil)
        source_field = pref_field || name
        define_singleton_method(name) do
          value = preference&.try(source_field).presence
          next value if value

          if credentials
            cred_value = Rails.application.credentials.dig(*credentials).presence
            next cred_value if cred_value
          end

          env ? ENV[env].presence : nil
        end
      end

      private

      def preference
        Preference.get_object(self::PREFERENCE_KEY)
      end
    end
  end
end
