# frozen_string_literal: true

# rbs_inline: enabled

class Site < ApplicationRecord
  has_many :articles, dependent: :nullify

  validates :name, :client, presence: true

  before_create do
    self.last_checked_at = Time.zone.now.beginning_of_year if last_checked_at.blank?
  end

  enum :client, [ :rss, :gmail, :youtube, :hacker_news ], default: :rss

  def init_client #: Object
    case client
    when "rss"
      RssClient.new(base_uri: base_uri)
    when "gmail"
      Gmail.new
    when "hacker_news"
      HackerNews.new
    when "youtube"
      Youtube::Channel.new(id: channel)
    else
      raise ArgumentError, "Unsupported client type: #{client}"
    end
  end
end
