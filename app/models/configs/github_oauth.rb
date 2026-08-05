# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Configs
  class GithubOauth < OauthBase
    preference_key "github_oauth"

    pref :client_id, env: "GITHUB_OAUTH_CLIENT_ID"
    pref :client_secret, env: "GITHUB_OAUTH_CLIENT_SECRET"

    def self.configured?
      client_id.present? && client_secret.present?
    end
  end
end
