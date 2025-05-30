# frozen_string_literal: true

# rbs_inline: enabled

class YoutubeContentTool < RubyLLM::Tool
  description "url을 통해 가져온 Youtube 콘텐츠에서 자막과 링크를 추출합니다."

  param :url, desc: "URL of the Youtube (e.g., https://www.youtube.com/watch?v=ErsF7_0bZnk)"

  #: (url String) -> String?
  def execute(url:)
    youtube_id = URI.decode_www_form(URI.parse(url).query).to_h["v"]
    return unless youtube_id

    transcript = nil
    video = Yt::Video.new id: youtube_id
    video.captions.map(&:language).each do |lang|
      rc = Youtube::Transcript.get(youtube_id, lang: lang)
      transcript = format_transcript(rc.dig("actions"))
      break if transcript.present?
    end
    transcript
  end

  private
  def format_transcript(actions)
    tsr = actions&.first&.dig("updateEngagementPanelAction", "content", "transcriptRenderer", "content", "transcriptSearchPanelRenderer", "body", "transcriptSegmentListRenderer", "initialSegments")
    return nil if tsr.nil? || tsr.empty?

    tsr.map { |it| it.dig("transcriptSegmentRenderer", "startTimeText", "simpleText").to_s + " - " + (it.dig("transcriptSegmentRenderer", "snippet", "runs")&.map { |it| it.dig("text") }&.join(" ") || "") }.join("\n")
  end
end
