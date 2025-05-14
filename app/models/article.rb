# frozen_string_literal: true

# rbs_inline: enabled

class Article < ApplicationRecord
  belongs_to :user, optional: true

  validates :url, presence: true, uniqueness: true

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

  IGNORE_HOSTS = %w[bsky.app threadreaderapp.com x.com]

  before_create do
    next unless url.is_a?(String)

    response = Faraday.get(url)
    logger.debug response.status
    self.url = response.headers["location"] if response.status == 301 || response.status == 302
    self.deleted_at = Time.zone.now if IGNORE_HOSTS.include?(URI.parse(url).host)
  end

  def generate_title #: void
    response = Faraday.get(url)
    doc = Nokogiri::HTML(response.body)
    title = doc.at("title")&.text
    update(title:) if title.is_a?(String)
  end

  def is_youtube? #: bool
    url.start_with?("https://www.youtube.com/watch?v=") || url.start_with?("https://youtu.be/")
  end


  def youtube_id #: string?
    url.split("?v=").last.split("&").first if is_youtube?
  end

  def youtube_transcript #: string?
    return unless is_youtube?

    rc = Youtube::Transcript.get(youtube_id)
    tsr = rc.dig("actions").first.dig("updateEngagementPanelAction", "content", "transcriptRenderer", "content", "transcriptSearchPanelRenderer", "body", "transcriptSegmentListRenderer", "initialSegments")
    tsr.map { |it| it.dig("transcriptSegmentRenderer", "startTimeText", "simpleText").to_s + " - " + it.dig("transcriptSegmentRenderer", "snippet", "runs").map { |it| it.dig("text") }.join(" ") }.join("\n")
  end
end
