# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class OauthBase
    class << self
      #: (String key) -> void
      def preference_key(key)
        @preference_key = key
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

      #: () -> Preference?
      def preference
        key = @preference_key or raise "#{name}에 preference_key가 정의되지 않았습니다"
        Preference.get_object(key)
      end
    end
  end
end
