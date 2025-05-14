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

    links.each do |link|
      Article.create(url: link) unless Article.exists?(url: link)
    end
  end
end
