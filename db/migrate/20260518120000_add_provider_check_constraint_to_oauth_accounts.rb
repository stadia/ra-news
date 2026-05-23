class AddProviderCheckConstraintToOauthAccounts < ActiveRecord::Migration[8.1]
  def up
    add_check_constraint :oauth_accounts, "provider IN ('google_oauth2', 'apple')", name: "oauth_accounts_provider_allowed"
  end

  def down
    remove_check_constraint :oauth_accounts, name: "oauth_accounts_provider_allowed"
  end
end
