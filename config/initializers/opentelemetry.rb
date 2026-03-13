# config/initializers/opentelemetry.rb

require "opentelemetry-exporter-otlp"
require "opentelemetry/instrumentation/rails"
require "opentelemetry/instrumentation/pg"
require "opentelemetry/instrumentation/http"
require "opentelemetry/instrumentation/logger"
require "opentelemetry/sdk"

OpenTelemetry::SDK.configure do |c|
  c.use_all() # enables all trace instrumentation!
end
