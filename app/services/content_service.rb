# frozen_string_literal: true

# rbs_inline: enabled

class ContentService < ApplicationService
  include LinkHelper

  attr_reader :article #: Article

  def initialize(article)
    @article = article
  end

  def call
    body = if article.is_youtube?
      # YouTube URL인 경우
      execute_youtube(article.url)
    else
      # YouTube URL이 아닌 경우
      execute_html(article.url)
    end
    body
  end

  protected

  #: (url: String) -> String?
  def execute_html(url)
    logger.info "Fetching HTML content from: #{url}"
    html_content = handle_redirection(url).body
    return nil if html_content.blank?

    # Readability를 사용하여 주요 콘텐츠 HTML 추출. Readability::Document는 전체 HTML 문자열을 인자로 받습니다.
    Readability::Document.new(html_content).content
  end

  #: (url: String) -> String?
  def execute_youtube(url)
    logger.info "Fetching Youtube content from: #{url}"
    youtube_id = youtube_id(url)
    logger.info "Youtube ID: #{youtube_id}"
    return unless youtube_id

    transcript = nil
    video = Yt::Video.new id: youtube_id
    begin
      video.captions.map(&:language).each do |lang|
        rc = Youtube::Transcript.get(youtube_id, lang: lang)
        next if rc["error"].present?

        transcript = format_transcript(rc.dig("actions"))
        break if transcript.present?
      end
    rescue StandardError => e
      logger.error "Error fetching Youtube transcript: #{e.message}"
    end

    if transcript.blank?
      begin
        fetched_transcript = YoutubeRb::Transcript::YouTubeTranscriptApi.new.fetch(youtube_id)
        transcript = YoutubeRb::Transcript::Formatters::TextFormatter.new.format_transcript(fetched_transcript) if fetched_transcript.present?
      rescue StandardError => e
        logger.error "Error fetching Youtube transcript: #{e.message}"
      end
    end

    transcript
  end

  private

  #: (String url, ?Integer? count) -> Faraday::Response
  def handle_redirection(url, count = 0)
    response = Faraday.get(url)
    logger.debug "#{response.status} #{url}"
    return response unless response.status.between?(300, 399) && response.headers["location"]
    return response if count > 3

    logger.debug response.headers["location"]
    # 3xx 응답인 경우 리다이렉트된 URL을 사용
    redirect_url = response.headers["location"]
    url = if redirect_url.start_with?("http")
                 redirect_url
    else
                 URI.join(url, redirect_url).to_s
    end
    logger.debug "Redirecting to: #{url}"

    handle_redirection(url, count + 1)
  end

  def format_transcript(actions)
    tsr = actions&.first&.dig("updateEngagementPanelAction", "content", "transcriptRenderer", "content", "transcriptSearchPanelRenderer", "body", "transcriptSegmentListRenderer", "initialSegments")
    return nil if tsr.nil? || tsr.empty?

    tsr.map { |it| "#{it.dig("transcriptSegmentRenderer", "startTimeText", "simpleText")} - #{it.dig("transcriptSegmentRenderer", "snippet", "runs")&.map { |run| run.dig("text") }&.join(" ")}" }.join("\n") # Use string interpolation for clarity
  end
end
