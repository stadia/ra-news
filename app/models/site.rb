# frozen_string_literal: true

# rbs_inline: enabled

class Site < ApplicationRecord
  has_many :articles, dependent: :nullify

  validates :name, :client, presence: true

  def init_client #: Object?
    return unless base_uri.is_a?(String)

    client.constantize.new(base_uri: base_uri)
  end

  def is_rss?
    client == "RssClient"
  end
end
