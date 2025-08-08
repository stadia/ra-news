# frozen_string_literal: true

Rails.application.configure do
  # ActivityPub configuration
  config.activitypub_enabled = Rails.env.production? || Rails.env.development?
  
  # Domain configuration for ActivityPub federation
  # In production, this should be set via environment variables
  config.activitypub_domain = ENV.fetch("ACTIVITYPUB_DOMAIN") do
    if Rails.env.production?
      config.hosts&.first || raise("ACTIVITYPUB_DOMAIN must be set in production")
    else
      "localhost:3000"
    end
  end
  
  # For development, allow localhost
  if Rails.env.development?
    config.hosts ||= []
    config.hosts << "localhost"
    config.hosts << "127.0.0.1"
  end
end