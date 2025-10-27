module LinkHelper
  protected

  # Extracts the target link from a given URL, handling various redirect and tracking services.
  #: (String link) -> String?
  def extract_link(link)
    return if link.start_with?("mailto:")

    uri = URI.parse(link)
    return if uri.host.blank?

    target = case uri.host
    when "maily.so", "www.libhunt.com"
               extract_url_param(uri)
    when "rubyweekly.com"
               handle_rubyweekly_link(link)
    when "link.mail.beehiiv.com"
               extract_redirect_location(link)
    else
               link
    end
    return if target.blank?

    normalized_uri = URI.parse(target)
    return if invalid_uri?(normalized_uri)

    target
  end

  # Checks if a URI is invalid for article creation.
  #: (URI uri) -> bool
  def invalid_uri?(uri)
    (uri.path.blank? || uri.path.size < 2) || Article.should_ignore_url?(uri.to_s)
  end

  # Extracts the 'url' parameter from a URI's query string.
  #: (URI uri) -> String?
  def extract_url_param(uri)
    return unless uri.query

    Rack::Utils.parse_nested_query(uri.query)["url"]
  end

  # Handles links from rubyweekly.com.
  #: (String link) -> String?
  def handle_rubyweekly_link(link)
    return unless link.starts_with?("https://rubyweekly.com/link")

    extract_redirect_location(link)
  end

  # Performs a GET request to find the redirect location.
  #: (String link) -> String?
  def extract_redirect_location(link)
    response = Faraday.get(link)
    response.headers["location"] if response.status.in?(300..399)
  end

  #: (String url) -> String?
  def youtube_id(url)
    # nil 체크를 포함하여 안전하게 접근
    if url.is_a?(String)
      uri = URI.parse(url)
      if uri.query.present?
        URI.decode_www_form(uri.query).to_h["v"]
      elsif uri.path.start_with?("/live")
        uri.path.split("/").last
      end
    end
  rescue URI::InvalidURIError
    logger.error "Invalid URI for youtube_id: #{url}"
    nil
  end
end
