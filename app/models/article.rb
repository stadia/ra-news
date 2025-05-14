# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  belongs_to :user, optional: true

  belongs_to :site, optional: true

  validates :url, :origin_url, presence: true, uniqueness: true

  after_create :generate_title

  after_create do
    next unless url.is_a?(String)

    ArticleJob.perform_later(id) if deleted_at.nil?
  end

  after_commit do
    next unless saved_change_to_url?

    ArticleJob.perform_later(id) if deleted_at.nil?
  end

  before_save do
    published_at = Time.zone.now if published_at.blank?
  end

  IGNORE_HOSTS = %w[meetup.com maily.so github.com bsky.app bsky.social threadreaderapp.com threads.com threads.net x.com linkedin.com meet.google.com twitch.tv inf.run lu.ma shortruby.com twitter.com facebook.com daily.dev] #: Array[String]

  def generate_metadata #: void
    return unless url.is_a?(String)

    response = Faraday.get(url)
    self.url = response.headers["location"] if response.status >= 300 && response.status < 400

    parsed_url = URI.parse(url)
    self.host = parsed_url.host
    self.deleted_at = Time.zone.now if parsed_url.path.nil? || parsed_url.path.size < 2 || Article::IGNORE_HOSTS.any? { |pattern| parsed_url.host.match?(/#{pattern}/i) }
    self.published_at = url_to_published_at || parse_to_published_at(response.body) || Time.zone.now

    doc = Nokogiri::HTML(response.body)
    temp_title = doc.at("title")&.text
    self.title = temp_title if temp_title.is_a?(String)
  end

  def is_youtube? #: bool
    url.start_with?("https://www.youtube.com/watch?") || url.start_with?("https://youtu.be/")
  end

  def youtube_id #: string?
    url.split("v=").last.split("&").first if is_youtube?
  end

  def youtube_transcript #: string?
    return unless is_youtube?

    rc = Youtube::Transcript.get(youtube_id)
    tsr = rc.dig("actions").first.dig("updateEngagementPanelAction", "content", "transcriptRenderer", "content", "transcriptSearchPanelRenderer", "body", "transcriptSegmentListRenderer", "initialSegments")
    return unless tsr

    tsr.map { |it| it.dig("transcriptSegmentRenderer", "startTimeText", "simpleText").to_s + " - " + it.dig("transcriptSegmentRenderer", "snippet", "runs").map { |it| it.dig("text") }.join(" ") }.join("\n")
  end

  def url_to_published_at #: DateTime?
    match_data = URI.parse(url).path.match(%r{(\d{4})[/-](\d{2})[/-](\d{2})})
    return unless match_data

    Time.zone.parse("#{match_data[1]}-#{match_data[2]}-#{match_data[3]}")
  end

  private

  def parse_to_published_at(body) #: DateTime?
    match_data = body.strip.match(/([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})/)
    return unless match_data

    Time.zone.parse("#{match_data[3]}-#{match_data[1]}-#{match_data[2]}")
  rescue StandardError => e
    puts "Error parsing published_at: #{e.message}"
    nil
  end
end
