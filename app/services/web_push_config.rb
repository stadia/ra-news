# frozen_string_literal: true

class WebPushConfig
  class << self
    def public_key
      read(:public_key, "WEB_PUSH_VAPID_PUBLIC_KEY")
    end

    def private_key
      read(:private_key, "WEB_PUSH_VAPID_PRIVATE_KEY")
    end

    def subject
      read(:subject, "WEB_PUSH_VAPID_SUBJECT")
    end

    def configured?
      public_key.present? && private_key.present? && subject.present?
    end

    private

    def read(credential_key, env_key)
      Rails.application.credentials.dig(:web_push, credential_key).presence || ENV[env_key].presence
    end
  end
end
