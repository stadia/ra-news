# frozen_string_literal: true

# rbs_inline: enabled

class GmailJob < ApplicationJob
  #: (email String) -> void
  def perform(email = nil)
    if email.nil?
      jobs = Site.where.not(email: nil).map { GmailJob.new(it.email) }
      ActiveJob.perform_all_later(jobs)
      return
    end

    links = Gmail.new.fetch_email_links(from: email)
    return if links.empty?

    logger.debug links
    links.each do |link|
      next if Article.exists?(origin_url: link)

      begin
        Article.create(url: link, origin_url: link)
      rescue StandardError => e
        logger.error e
      end
    end
  end
end
