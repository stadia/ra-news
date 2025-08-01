# frozen_string_literal: true

X.configure do |config|
  # Validate required environment variables at startup
  required_vars = %w[X_BEARER_TOKEN X_API_KEY X_API_KEY_SECRET X_ACCESS_TOKEN X_ACCESS_TOKEN_SECRET]
  missing_vars = required_vars.select { |var| ENV[var].blank? }

  if missing_vars.any?
    Rails.logger.warn "Missing X/Twitter environment variables: #{missing_vars.join(', ')} - Twitter posting will be disabled"
    # Don't raise in production to prevent app startup failure
    # Instead, the job will fail gracefully when trying to post
  end

  config.bearer_token = ENV["X_BEARER_TOKEN"]
  config.api_key = ENV["X_API_KEY"]
  config.api_key_secret = ENV["X_API_KEY_SECRET"]
  config.access_token = ENV["X_ACCESS_TOKEN"]
  config.access_token_secret = ENV["X_ACCESS_TOKEN_SECRET"]
end
