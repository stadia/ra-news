# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class RssSitePageJob < ApplicationJob
  include RssHelper
  include LinkHelper

  def self.enqueue_all
    RssSitePageJob.perform_later(Site.kept.rss_page.order("id ASC").pluck(:id))
  end

  #: (Array[Integer] ids) -> void
  def perform(ids)
    ids = [ ids ] unless ids.is_a?(Array)
    site_id = ids.shift
    site = Site.find(site_id)

    Rss::PageCrawler.crawl(site)

    logger.info "site #{site.id} RssSitePageJob finished"
    site.update!(last_checked_at: Time.zone.now)
    RssSitePageJob.perform_later(ids) unless ids.empty?
  end
end
