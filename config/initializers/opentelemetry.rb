# config/initializers/opentelemetry.rb
# Configure OpenTelemetry Traces and Logs
OpenTelemetry::SDK.configure do |c|
  c.service_name = "ruby-news"

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
