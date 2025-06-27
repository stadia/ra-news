module LinkHelper
  protected

  # Extracts the target link from a given URL, handling various redirect and tracking services.
  #: (link String) -> String?
  def extract_link(link)
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
  #: (uri URI) -> bool
  def invalid_uri?(uri)
    (uri.path.blank? || uri.path.size < 2) || Article.should_ignore_url?(uri.to_s)
  end

  # Extracts the 'url' parameter from a URI's query string.
  #: (uri URI) -> String?
  def extract_url_param(uri)
    return unless uri.query

    Rack::Utils.parse_nested_query(uri.query)["url"]
  end

  # Handles links from rubyweekly.com.
  #: (link String) -> String?
  def handle_rubyweekly_link(link)
    return unless link.starts_with?("https://rubyweekly.com/link")

    extract_redirect_location(link)
  end

  # Performs a GET request to find the redirect location.
  #: (link String) -> String?
  def extract_redirect_location(link)
    response = Faraday.get(link)
    response.headers["location"] if response.status.in?(300..399)
  end
end
