# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class Site < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  has_many :articles, dependent: :destroy

  validates :name, :client, presence: true
  validates :url, uniqueness: true, if: -> { rss? }, allow_nil: true

  before_save :parse_url_to_uri_parts, if: :will_save_change_to_url?

  before_create do
    self.last_checked_at = 6.months.ago if last_checked_at.blank?
  end

  enum :client, [ :rss, :gmail, :youtube, :hacker_news, :rss_page, :reddit ], default: :rss

  #: () -> untyped
  def init_client
    case client
    when "gmail"
      Gmail.new
    when "youtube"
      return nil if channel.blank?

      Youtube::Channel.new(id: channel)
    else
      raise ArgumentError, "Unsupported client type: #{client}"
    end
  end

  private

  #: () -> void
  def parse_url_to_uri_parts
    return if url.blank?

    parsed = URI.parse(url)
    return if parsed.scheme.blank? || parsed.host.blank?

    port_part = ":#{parsed.port}" if parsed.port && ![ 80, 443 ].include?(parsed.port)
    self.base_uri = "#{parsed.scheme}://#{parsed.host}#{port_part}"
    self.path = parsed.path.presence || "/"
  rescue URI::InvalidURIError
    # url이 유효하지 않으면 base_uri/path를 그대로 둔다
  end
end
