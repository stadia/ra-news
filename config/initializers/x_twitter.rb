# frozen_string_literal: true

X.configure do |config|
  config.bearer_token = ENV["X_BEARER_TOKEN"]
  config.api_key = ENV["X_API_KEY"]
  config.api_key_secret = ENV["X_API_KEY_SECRET"]
  config.access_token = ENV["X_ACCESS_TOKEN"]
  config.access_token_secret = ENV["X_ACCESS_TOKEN_SECRET"]
end