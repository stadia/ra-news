require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache digest stamped assets for far-future expiry.
  # Short cache for others: robots.txt, sitemap.xml, 404.html, etc.
  config.public_file_server.headers = {
    "cache-control" => lambda do |path, _|
      if path.start_with?("/assets/")
        # Files in /assets/ are expected to be fully immutable.
        # If the content change the URL too.
        "public, immutable, max-age=#{1.year.to_i}"
      else
        # For anything else we cache for 1 minute.
        "public, max-age=#{1.minute.to_i}, stale-while-revalidate=#{5.minutes.to_i}"
      end
    end
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = "https://assets.ruby-news.kr"

  # Store uploaded files on Cloudflare R2 (S3-compatible; see config/storage.yml).
  config.active_storage.service = :cloudflare

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = { request_id: :request_id, ip: :remote_ip }
  $stdout.sync = true
  config.rails_semantic_logger.add_file_appender = false
  config.semantic_logger.add_appender(io: $stdout, formatter: config.rails_semantic_logger.format)
  # OTel appender is added in config/initializers/opentelemetry.rb
  # after SDK.configure to avoid ProxyLoggerProvider API mismatch
  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").downcase.strip.to_sym

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store
  config.session_store :cache_store, expire_after: 1.weeks

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "ruby-news.kr" }

  # Set default URL options for URL helpers
  Rails.application.routes.default_url_options = { host: "ruby-news.kr" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  config.action_mailer.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: 587,
    user_name: "apikey",
    password: Rails.application.credentials.dig(:smtp, :password),
    authentication: :plain,
    enable_starttls_auto: true,
    enable_starttls: true,
    domain: "ruby-news.kr"
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins "https://ruby-news.kr", "https://ruby-news.jp"
      resource "/assets/*", headers: :any, methods: [ :get, :head, :options ]
    end
  end
end
