# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class Discord < OauthBase
    preference_key "discord_oauth"

    pref :client_id
    pref :client_secret
    pref :bot_token, credentials: %i[discord bot_token], env: "DISCORD_BOT_TOKEN"

    def self.configured?
      client_id.present? && client_secret.present? && bot_token.present?
    end
  end
end
