# config/initializers/opentelemetry.rb
# Configure OpenTelemetry Traces and Logs
otel_endpoint = ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].presence
skip_otel = otel_endpoint.blank? && (Rails.env.development? || Rails.env.test?)

module OTelAttributeSanitizer
  module_function

  def sanitize_attributes(attributes)
    return unless attributes.respond_to?(:each_pair)

    attributes.each_with_object({}) do |(key, value), sanitized|
      normalized = normalize_value(value)
      sanitized[key.to_s] = normalized unless normalized.nil?
    end
  end

  def normalize_value(value)
    case value
    when String, Integer, Float, TrueClass, FalseClass
      value
    when Symbol
      value.to_s
    when Time, Date, DateTime
      value.iso8601
    when Array
      normalize_array(value)
    when Hash
      JSON.generate(value.to_h { |k, v| [ k.to_s, normalize_json_value(v) ] })
    else
      if value.respond_to?(:to_h)
        JSON.generate(value.to_h { |k, v| [ k.to_s, normalize_json_value(v) ] })
      elsif value.respond_to?(:as_json)
        normalize_value(value.as_json)
      else
        value.to_s
      end
    end
  end

  def normalize_array(values)
    normalized = values.map { |value| normalize_value(value) }.compact
    return normalized if normalized.empty?

    first = normalized.first
    return normalized if scalar_array?(normalized, first.class)

    JSON.generate(values.map { |value| normalize_json_value(value) })
  end

  def scalar_array?(values, klass)
    case klass.name
    when "String"
      values.all? { |value| value.instance_of?(String) }
    when "Integer", "Float"
      values.all? { |value| value.instance_of?(Integer) || value.instance_of?(Float) }
    when "TrueClass", "FalseClass"
      values.all? { |value| value == true || value == false }
    else
      false
    end
  end

  def normalize_json_value(value)
    case value
    when String, Integer, Float, TrueClass, FalseClass, NilClass
      value
    when Symbol
      value.to_s
    when Time, Date, DateTime
      value.iso8601
    when Array
      value.map { |item| normalize_json_value(item) }
    when Hash
      value.to_h { |k, v| [ k.to_s, normalize_json_value(v) ] }
    else
      if value.respond_to?(:to_h)
        value.to_h { |k, v| [ k.to_s, normalize_json_value(v) ] }
      elsif value.respond_to?(:as_json)
        normalize_json_value(value.as_json)
      else
        value.to_s
      end
    end
  end
end

module SemanticLogger
  module Formatters
    class OpenTelemetry
      def payload
        return unless log.payload.respond_to?(:empty?) && !log.payload.empty?

        hash[:payload] = OTelAttributeSanitizer.sanitize_attributes(log.payload)
      end
    end
  end
end

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
