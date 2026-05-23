# frozen_string_literal: true

class AllowGithubOauthAccounts < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :oauth_accounts, name: "oauth_accounts_provider_allowed"
    add_check_constraint :oauth_accounts, "provider IN ('google_oauth2', 'apple', 'github')", name: "oauth_accounts_provider_allowed"
  end
end
