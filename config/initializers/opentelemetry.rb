# config/initializers/opentelemetry.rb

if Rails.env.production?
  require "opentelemetry/sdk"
  require "opentelemetry-exporter-otlp"
  require "opentelemetry-logs-sdk"
  require "opentelemetry-exporter-otlp-logs"
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

  # --- Logs: send structured records to SigNoz over OTLP ---
  # rails_semantic_logger still writes JSON to $stdout (see production.rb) for
  # `kubectl logs`. This appender additionally emits OTLP LogRecords where the
  # log `payload` becomes structured `attributes`, so SigNoz can index/filter
  # fields instead of storing the whole JSON line as an opaque `body` string.
  #
  # Endpoint/headers come from the standard OTEL_EXPORTER_OTLP_* env vars
  # (falls back to OTEL_EXPORTER_OTLP_LOGS_ENDPOINT), same as traces.
  logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new(
    resource: OpenTelemetry::SDK::Resources::Resource.create("service.name" => "ruby-news")
  )
  logger_provider.add_log_record_processor(
    OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
      OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
    )
  )
  OpenTelemetry.logger_provider = logger_provider

  # Must run AFTER logger_provider is set: the appender captures the provider
  # at construction time. metrics:false — no meter pipeline is configured.
  SemanticLogger.add_appender(appender: :open_telemetry, metrics: false)

  at_exit { logger_provider.shutdown }
end
