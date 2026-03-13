# config/initializers/opentelemetry.rb
# Configure OpenTelemetry Traces and Logs
OpenTelemetry::SDK.configure do |c|
  c.service_name = "ruby-news"
  c.service_version = "1.0"

  # Add log record processor for OTLP export
  logs_exporter = OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
  logs_processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(logs_exporter)
  c.add_log_record_processor(logs_processor)

  # Configure trace instrumentations
  c.use_all({
    "OpenTelemetry::Instrumentation::Net::HTTP" => {
      untraced_hosts: [ /sentry/, /newrelic/ ]
    }
  })
end

# Register SemanticLogger OTel appender AFTER SDK is configured
# to avoid ProxyLoggerProvider positional/keyword args mismatch
if ENV["OTEL_EXPORTER_OTLP_ENDPOINT"]
  SemanticLogger.add_appender(appender: :open_telemetry)
end
