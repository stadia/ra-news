# frozen_string_literal: true

# rbs_inline: enabled

class Site < ApplicationRecord
  has_many :articles, dependent: :nullify

  validates :name, :client, presence: true

  before_create do
    self.last_checked_at = Time.zone.now.beginning_of_month if last_checked_at.blank?
  end

  def init_client #: Object?
    return Youtube::Channel.new(id: channel) if is_youtube?

    return unless base_uri.is_a?(String)

    client.constantize.new(base_uri: base_uri)
  end

  def is_rss? #: bool
    client == "RssClient"
  end

  def is_youtube? #: bool
    channel.present? && client == "Youtube::Channel"
  end
end
