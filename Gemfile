source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails", "~> 4.2"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication [https://github.com/heartcombo/devise]
gem "devise", "~> 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Patch-level verification for Bundler [https://github.com/rubysec/bundler-audit]
  gem "bundler-audit", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rbs_inline", require: false
  # gem "steep", require: false
  gem "dotenv-rails"
  gem "faker"
  gem "minitest", "~> 6.0"
  gem "minitest-mock"
  gem "tapioca", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "letter_opener"
  gem "ruby-lsp-brakeman", require: false
  gem "ruby-lsp-i18n", require: false
  gem "ruby_ui", "~> 1.1"
  gem "sorbet"
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem "google-protobuf", require: false
gem "pagy", "~> 43.5" # omit patch digit
gem "sorbet-runtime"
# silence Ruby 3.4 warnings
gem "acts-as-taggable-on"
gem "awesome_nested_set"
gem "discard"
gem "hairtrigger"
gem "kramdown"
gem "madmin", "~> 2.3"
gem "meta-tags"
gem "mission_control-jobs"
gem "neighbor"
gem "oauth2", "~> 2.0"
gem "ostruct"
gem "pg_search"
gem "rails-i18n"
gem "rss"
gem "ruby-readability"
gem "schema_dot_org"
gem "sitemap_generator"
gem "yt"
# Use sqlite3 as the database for Active Record
gem "dry-operation"
gem "pg_reports", "~> 0.6.0"
gem "sqlite3", ">= 2.1"
gem "youtube-transcript-rb", "~> 0.2.0"

gem "amazing_print"
gem "appsignal"
gem "federails", github: "stadia/federails"
# gem "federails", path: "../federails"
gem "friendly_id"
gem "lexxy", "~> 0.9.8.beta"
gem "oj"
gem "pg_query"
gem "phlex-icons"
gem "phlex-rails", "~> 2.4"
gem "prosopite"
gem "rails-ai-context"
gem "rails_semantic_logger"
# gem "rorvswild"
gem "discordrb-webhooks"
gem "rack-cors"
gem "ruby_llm", "~> 1.14"
gem "ruby_llm-schema"
gem "ruby-mcp-client", "~> 1.0"
gem "slack-ruby-client", "~> 3.1.0"
gem "socialization"
gem "tailwind_merge", "~> 1.4"
gem "web-push", "~> 3.1"

gem "opentelemetry-exporter-otlp"
gem "opentelemetry-exporter-otlp-logs"
gem "opentelemetry-instrumentation-concurrent_ruby"
gem "opentelemetry-instrumentation-ethon"
gem "opentelemetry-instrumentation-faraday"
gem "opentelemetry-instrumentation-http"
gem "opentelemetry-instrumentation-http_client"
gem "opentelemetry-instrumentation-net_http"
gem "opentelemetry-instrumentation-pg"
gem "opentelemetry-instrumentation-rails"
gem "opentelemetry-instrumentation-rake"
gem "opentelemetry-instrumentation-ruby_llm"
gem "opentelemetry-sdk", "~> 1.10"
