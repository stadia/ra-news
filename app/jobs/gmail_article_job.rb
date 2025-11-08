# frozen_string_literal: true

# rbs_inline: enabled

class GmailArticleJob < ApplicationJob
  include LinkHelper

  def self.enqueue_all
    GmailArticleJob.perform_later(Site.kept.gmail.order("id ASC").pluck(:id))
  end

  # Performs the job for a given site ID.
  #: (Array[Integer] ids) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)
    return if site.email.blank?

    links = fetch_new_email_links(site)
    if links.empty?
      site.update!(last_checked_at: Time.zone.now)
      GmailArticleJob.perform_later(ids) unless ids.empty?
      return
    end

    create_articles_from_links(links, site)

    site.update!(last_checked_at: Time.zone.now)
    GmailArticleJob.perform_later(ids) unless ids.empty?
  end

  private

  # Fetches new email links from the site's email account.
  #: (Site site) -> Array<String>
  def fetch_new_email_links(site)
    site.init_client.fetch_email_links(from: site.email, since: site.last_checked_at - 1.day)
  end

  # Iterates over links and creates articles.
  #: (Array<String> links, Site site) -> void
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
  #: (String link, Site site) -> void
  def create_article(link, site)
    Article.create!(url: link, origin_url: link, site: site)
    logger.info "Created article for #{link}"
    sleep 1
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Failed to create article for #{link}: #{e.message}"
  rescue ActiveRecord::RecordNotUnique => e
    logger.error "Article already exists for #{link}: #{e.message}"
  end
end
