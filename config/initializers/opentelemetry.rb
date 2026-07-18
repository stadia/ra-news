# config/initializers/opentelemetry.rb

if Rails.env.production?
  require "opentelemetry/sdk"
  require "opentelemetry-exporter-otlp"
  require "opentelemetry/instrumentation/aws_sdk"
  require "opentelemetry/instrumentation/concurrent_ruby"
  require "opentelemetry/instrumentation/faraday"
  require "opentelemetry/instrumentation/grpc"
  require "opentelemetry/instrumentation/net/http"
  require "opentelemetry/instrumentation/pg"
  require "opentelemetry/instrumentation/rack"
  require "opentelemetry/instrumentation/rails"
  require "opentelemetry/instrumentation/rake"
  require "opentelemetry-instrumentation-ruby_llm"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = "ruby-news"
    c.use_all
  end
end
