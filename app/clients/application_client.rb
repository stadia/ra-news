# frozen_string_literal: true
# rbs_inline: enabled

class ApplicationClient
  class Error < StandardError; end
  class Forbidden < Error; end
  class Unauthorized < Error; end
  class RateLimit < Error; end
  class NotFound < Error; end
  class InternalError < Error; end

  #: (?url: String) -> ApplicationClient
  def initialize(url: BASE_URI)
    @url = url
  end

  attr_reader :url

  #: (String path, ?headers: Hash, ?query: untyped) -> Faraday::Response
  def get(path, headers: {}, query: nil)
    request(:get, path, headers: headers, query: query)
  end

  #: (String path, ?headers: Hash, ?query: untyped, ?body: untyped, ?form_data: untyped) -> Faraday::Response
  def post(path, headers: {}, query: nil, body: nil, form_data: nil)
    request(:post, path, headers: headers, query: query, body: body, form_data: form_data)
  end

  #: (String path, ?headers: Hash, ?query: untyped, ?body: untyped, ?form_data: untyped) -> Faraday::Response
  def patch(path, headers: {}, query: nil, body: nil, form_data: nil)
    request(:patch, path, headers: headers, query: query, body: body, form_data: form_data)
  end

  #: (String path, ?headers: Hash, ?query: untyped, ?body: untyped, ?form_data: untyped) -> Faraday::Response
  def put(path, headers: {}, query: nil, body: nil, form_data: nil)
    request(:put, path, headers: headers, query: query, body: body, form_data: form_data)
  end

  #: (String path, ?headers: Hash, ?query: untyped, ?body: untyped) -> Faraday::Response
  def delete(path, headers: {}, query: nil, body: nil)
    request(:delete, path, headers: headers, query: query, body: body)
  end

  #: (Faraday::Response) -> Faraday::Response
  def handle_response(response)
    case response.status.to_i
    when 200..204 then response
    when 401     then raise Unauthorized, "Unauthorized: #{response.body}"
    when 403     then raise Forbidden, "Forbidden: #{response.body}"
    when 404     then raise NotFound, "Not Found: #{response.body}"
    when 429     then raise RateLimit, "Rate Limited: #{response.body}"
    when 500..599 then raise InternalError, "Server Error (#{response.status}): #{response.body}"
    else              raise Error, "HTTP Error #{response.status}: #{response.body}"
    end
  end

  protected

  def logger
    Rails.logger
  end

  def content_type #: String
    "application/json"
  end

  def default_query_params #: Hash[String, String]
    {}
  end

  private

  BASE_URI = "https://example.org"
  HTTP_METHODS = %i[get post patch put delete].freeze
  private_constant :BASE_URI, :HTTP_METHODS

  #: (Symbol method, String path, ?headers: Hash, ?query: untyped, ?body: untyped, ?form_data: untyped) -> Faraday::Response
  def request(method, path, headers: {}, query: nil, body: nil, form_data: nil)
    raise ArgumentError, "Cannot pass both body and form_data" if body.present? && form_data.present?
    raise ArgumentError, "Unsupported HTTP method: #{method}" unless HTTP_METHODS.include?(method)

    uri = build_uri(path, query)
    all_headers = build_headers(headers, method)

    logger.debug("#{method.to_s.upcase}: #{uri}")

    build_connection(uri, all_headers, form_data).public_send(method, uri.request_uri, request_body(body, form_data)) do |req|
      req.params = uri.query if uri.query.present?
    end
  end

  #: (String path, untyped query) -> URI::Generic
  def build_uri(path, query)
    uri = URI("#{url}#{path}")
    merged = Rack::Utils.parse_query(uri.query).with_defaults(default_query_params).merge(query || {})
    uri.query = Rack::Utils.build_query(merged) if merged.present?
    uri
  end

  #: (Hash headers, Symbol method) -> Hash[String, String]
  def build_headers(headers, method)
    h = { "Accept" => content_type, "Content-Type" => content_type }.merge(headers)
    h.delete("Content-Type") if method == :get
    h
  end

  #: (untyped body, untyped form_data) -> String?
  def request_body(body, form_data)
    form_data || build_body(body)
  end

  #: (untyped body) -> String?
  def build_body(body)
    case body
    when String then body
    when NilClass then nil
    else body.to_json
    end
  end

  #: (URI uri, Hash headers, untyped form_data) -> Faraday::Connection
  def build_connection(uri, headers, form_data)
    Faraday.new(url: "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port && ![80, 443].include?(uri.port)}", headers: headers) do |conn|
      conn.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                   exceptions: [Errno::ETIMEDOUT, "Timeout::Error", Faraday::TimeoutError]

      if form_data.present?
        conn.request :url_encoded
      elsif headers["Accept"] == "application/json"
        conn.request :json
      end

      conn.response :json, content_type: /\bjson$/
      conn.options.timeout = 30
      conn.options.open_timeout = 10
    end
  end
end