# frozen_string_literal: true

class WebPushConfig
  DEFAULT_EXPIRATION_SECONDS = 600
  MAX_EXPIRATION_SECONDS = 3_600

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

    def expiration_seconds
      raw = ENV["WEB_PUSH_VAPID_EXPIRATION_SECONDS"].to_i
      seconds = raw.positive? ? raw : DEFAULT_EXPIRATION_SECONDS

      [ seconds, MAX_EXPIRATION_SECONDS ].min
    end

    private

    def read(credential_key, env_key)
      Rails.application.credentials.dig(:web_push, credential_key).presence || ENV[env_key].presence
    end
  end
end
