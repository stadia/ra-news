# config/initializers/opentelemetry.rb
# Configure OpenTelemetry Traces and Logs
otel_endpoint = ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].presence
skip_otel = otel_endpoint.blank? && (Rails.env.development? || Rails.env.test?)

unless skip_otel
  OpenTelemetry::SDK.configure do |c|
    c.service_name = "ruby-news"
    c.service_version = "1.0"

    # Add log record processor for OTLP export
    if otel_endpoint.present?
      logs_exporter = OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
      logs_processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(logs_exporter)
      c.add_log_record_processor(logs_processor)
    end

    # Configure trace instrumentations
    c.use_all({
      "OpenTelemetry::Instrumentation::Net::HTTP" => {
        untraced_hosts: [ /sentry/, /newrelic/, /honeybadger/ ]
      }
    })
  end
end

# Register SemanticLogger OTel appender AFTER SDK is configured
# to avoid ProxyLoggerProvider positional/keyword args mismatch
if otel_endpoint.present?
  SemanticLogger.add_appender(appender: :open_telemetry)
end
