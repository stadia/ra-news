# frozen_string_literal: true

module OauthAccounts
  module UsernameSuggester
    MIN_LENGTH = 2
    MAX_LENGTH = 30

    module_function

    def suggest_username(name:, email:)
      base = sanitize(name).presence || sanitize(email.to_s.split("@").first).presence || "user"
      base = "user#{base}" if base.length < MIN_LENGTH
      base = base.first(MAX_LENGTH)

      unique_username_for(base)
    end

    def sanitize(value)
      value.to_s.downcase
           .gsub(/\s+/, "_")
           .gsub(/[^a-z0-9_.]/, "")
           .gsub(/_{2,}/, "_")
           .gsub(/\A[._]+|[._]+\z/, "")
    end

    def unique_username_for(base)
      return base unless User.exists?(username: base)

      suffix = 1
      loop do
        candidate = "#{base.first(MAX_LENGTH - suffix.to_s.length - 1)}_#{suffix}"
        return candidate unless User.exists?(username: candidate)

        suffix += 1
      end
    end
  end
end
