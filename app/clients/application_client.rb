class ApplicationClient
  class Error < StandardError; end

  class Forbidden < Error; end

  class Unauthorized < Error; end

  class RateLimit < Error; end

  class NotFound < Error; end

  class InternalError < Error; end

  BASE_URI = "https://example.org"
  NET_HTTP_ERRORS = [ Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError ]

  def initialize(token: nil)
    @token = token
  end

  def default_headers
    {
      "Accept" => content_type,
      "Content-Type" => content_type
    }.merge(authorization_header)
  end

  def content_type
    "application/json"
  end

  def authorization_header
    token ? { "Authorization" => "Bearer #{token}" } : {}
  end

  def default_query_params
    {}
  end

  def get(path, headers: {}, query: nil)
    make_request(klass: Net::HTTP::Get, path: path, headers: headers, query: query)
  end

  def post(path, headers: {}, query: nil, body: nil, form_data: nil)
    make_request(
      klass: Net::HTTP::Post,
      path: path,
      headers: headers,
      query: query,
      body: body,
      form_data: form_data
    )
  end

  def patch(path, headers: {}, query: nil, body: nil, form_data: nil)
    make_request(
      klass: Net::HTTP::Patch,
      path: path,
      headers: headers,
      query: query,
      body: body,
      form_data: form_data
    )
  end

  def put(path, headers: {}, query: nil, body: nil, form_data: nil)
    make_request(
      klass: Net::HTTP::Put,
      path: path,
      headers: headers,
      query: query,
      body: body,
      form_data: form_data
    )
  end

  def delete(path, headers: {}, query: nil, body: nil)
    make_request(klass: Net::HTTP::Delete, path: path, headers: headers, query: query, body: body)
  end

  def base_uri
    self.class::BASE_URI
  end

  attr_reader :token

  def make_request(klass:, path:, headers: {}, body: nil, query: nil, form_data: nil)
    raise ArgumentError, "Cannot pass both body and form_data" if body.present? && form_data.present?

    uri = URI("#{base_uri}#{path}")
    existing_params = Rack::Utils.parse_query(uri.query).with_defaults(default_query_params)
    query_params = existing_params.merge(query || {})
    uri.query = Rack::Utils.build_query(query_params) if query_params.present?

    Rails.logger.debug("#{klass.name.split("::").last.upcase}: #{uri}")

    all_headers = default_headers.merge(headers)
    all_headers.delete("Content-Type") if klass == Net::HTTP::Get

    conn = if form_data.present?
      Faraday.new(url: "#{uri.scheme}://#{uri.host}", headers: all_headers) do |conn|
        conn.request :url_encoded
      end
    else
      Faraday.new(url: "#{uri.scheme}://#{uri.host}", headers: all_headers)
    end

    response = case klass
    when Net::HTTP::Get.class
      conn.get(uri.request_uri) do |req|
        req.params = uri.query if query_params.present?
      end
    when Net::HTTP::Post.class
      conn.post(uri.request_uri, build_body(body) || form_data) do |req|
        req.params = uri.query if query_params.present?
      end
    when Net::HTTP::Patch.class
      conn.patch(uri.request_uri, build_body(body) || form_data) do |req|
        req.params = uri.query if query_params.present?
      end
    when Net::HTTP::Put.class
      conn.put(uri.request_uri, build_body(body)) do |req|
        req.params = uri.query if query_params.present?
      end
    when Net::HTTP::Delete.class
      conn.delete(uri.request_uri) do |req|
        req.params = uri.query if query_params.present?
      end
    end

    response
  end

  def handle_response(response)
    case response.status
    when "200", "201", "202", "203", "204"
      response
    when "401"
      raise Unauthorized, response.body
    when "403"
      raise Forbidden, response.body
    when "404"
      raise NotFound, response.body
    when "429"
      raise RateLimit, response.body
    when "500"
      raise InternalError, response.body
    else
      raise Error, "#{response.status} - #{response.body}"
    end
  end

  def build_body(body)
    case body
    when String
      body
    else
      body.to_json
    end
  end
end
