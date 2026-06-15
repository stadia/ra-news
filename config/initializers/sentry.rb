# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]
  config.environment = Rails.env
  config.release = ENV["APP_REVISION"] if ENV["APP_REVISION"].present?
  config.server_name = ENV["HOSTNAME"] if ENV["HOSTNAME"].present?

  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Free plan friendly defaults:
  # - keep error reporting enabled
  # - avoid high-volume tracing/profiling by default
  # - minimize PII collection
  # config.send_default_pii = false
  # config.include_local_variables = false
  # config.max_breadcrumbs = 30

  config.excluded_exceptions += [
    "ActionController::RoutingError",
    "ActiveRecord::RecordNotFound",
    "ActionController::InvalidAuthenticityToken",
    "ActionController::UnknownFormat"
  ]

  # config.before_send = lambda do |event, hint|
  #   request = hint[:rack_env]

  #   if request
  #     path = request['PATH_INFO'].to_s
  #     return nil if path.start_with?('/up', '/health', '/cable', '/rails/active_storage')
  #   end

  #   event.user = {}

  #   event.request&.data&.except!(
  #     'password',
  #     'password_confirmation',
  #     'current_password',
  #     'token',
  #     'secret'
  #   )

  #   event
  # end
end
