class OtelJsonFormatter < SemanticLogger::Formatters::Raw
  def call(log, logger)
    span = OpenTelemetry::Trace.current_span
    span_id = span.context.hex_span_id
    trace_id = span.context.hex_trace_id
    operation = span.respond_to?(:name) ? span.name : "undefined"
    super
    hash[:trace_id] = trace_id
    hash[:span_id] = span_id
    hash[:operation] = operation
    hash.to_json
  end
end
