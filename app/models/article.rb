# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  belongs_to :user, optional: true

  after_create :generate_title

  after_commit do
    next unless saved_change_to_url?

    ArticleJob.perform_later(id)
  end

  def generate_title #: void
    response = Faraday.get(url)
    if response.status == 301
      update(url: response.headers["location"])
      response = Faraday.get(url)
    end
    doc = Nokogiri::HTML(response.body)
    title = doc.at("title").text
    update(title:) if title.is_a?(String)
  end
end
