# frozen_string_literal: true

# rbs_inline: enabled

class GmailArticleJob < ApplicationJob
  # Enqueues a job for each Gmail site.
  def self.enqueue_all #: void
    start = -2
    ActiveJob.perform_all_later(Site.gmail.map { |site| start += 2; GmailArticleJob.new(site.id).set(wait: start.minutes) })
  end

  # Performs the job for a given site ID.
  #: (site_id ?int) -> void
  def perform(site_id = nil)
    GmailArticleJob.enqueue_all and return if site_id.blank?

    site = Site.find(site_id)
    return if site.email.blank?

    links = fetch_new_email_links(site)
    return if links.empty?

    create_articles_from_links(links, site)

    site.update!(last_checked_at: Time.zone.now)
  end

  private

  # Fetches new email links from the site's email account.
  #: (site Site) -> Array<String>
  def fetch_new_email_links(site)
    site.init_client.fetch_email_links(from: site.email, since: site.last_checked_at - 1.day)
  end

  # Iterates over links and creates articles.
  #: (links Array<String>, site Site) -> void
  def create_articles_from_links(links, site)
    links.each do |link|
      processed_link = extract_link(link)
      next if processed_link.blank?

      logger.info "Processing link: #{processed_link}"
      next if Article.exists?(origin_url: processed_link)

      create_article(processed_link, site)
    end
  end

  # Creates an article for a given link.
  #: (link String, site Site) -> void
  def create_article(link, site)
    Article.create!(url: link, origin_url: link, site: site)
    logger.info "Created article for #{link}"
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Failed to create article for #{link}: #{e.message}"
  end

  # Extracts the target link from a given URL, handling various redirect and tracking services.
  #: (link String) -> String?
  def extract_link(link)
    uri = URI.parse(link)
    target = case uri.host
    when "maily.so", "www.libhunt.com"
               extract_url_param(uri)
    when "rubyweekly.com"
               handle_rubyweekly_link(link)
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
    (uri.path.blank? || uri.path.size < 2) ||
      Article::IGNORE_HOSTS.any? { |pattern| uri.host&.match?(/#{pattern}/i) }
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
