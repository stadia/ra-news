# frozen_string_literal: true
# rbs_inline: enabled

module ArticleHumanizer
  module_function

  #: (Article article) -> String
  def prompt(article)
    keys = Array(article.summary_key).map(&:to_s).reject(&:blank?)
    details = article.summary_detail.to_h.transform_values(&:to_s)
    body = article.summary_body.to_s

    <<~PROMPT
      /humanize
      응답은 아래 JSON 형식만 반환하라.
      JSON 외에 설명·코멘트·상태줄·마크다운 코드펜스·구분선을 절대 포함하지 마라.
      JSON 키와 구조를 임의로 변경하지 마라.

      {
        "summary_key": #{keys.to_json},
        "summary_detail": #{details.to_json},
        "summary_body": #{body.to_json}
      }

      각 필드의 내용만 윤문하여 동일한 JSON 구조로 반환하라.
      summary_key는 문자열 배열, summary_detail은 문자열 해시, summary_body는 마크다운 문자열이다.
    PROMPT
  end

  #: (untyped content) -> Hash[Symbol, untyped]
  def extract_content(content)
    text = content.to_s.strip
    json = extract_json(text)

    if json.present?
      build_result_from_json(json)
    else
      # 폴백: JSON 파싱 실패 시 기존 태그 기반 파싱
      tagged_body = extract_tagged_block(text, "SUMMARY_BODY")
      if tagged_body.present?
        {
          summary_key: extract_summary_key(text),
          summary_detail: extract_summary_detail(text),
          summary_body: clean_body(tagged_body)
        }
      else
        { summary_body: extract_body_fallback(text) }
      end
    end
  end

  # --- JSON 파싱 ---

  #: (String text) -> Hash?
  def extract_json(text)
    cleaned = text.sub(/\A```(?:json)?\s*\n?/m, "").sub(/\n?```\s*\z/m, "")
    json_match = cleaned.match(/\{.*\}/m)
    return nil unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError
    nil
  end

  #: (Hash json) -> Hash[Symbol, untyped]
  def build_result_from_json(json)
    result = {}

    if json["summary_key"].is_a?(Array)
      result[:summary_key] = json["summary_key"].map(&:to_s).reject(&:blank?)
    end

    if json["summary_detail"].is_a?(Hash)
      result[:summary_detail] = json["summary_detail"].transform_values(&:to_s)
    end

    body = json["summary_body"].to_s.strip
    if body.present?
      result[:summary_body] = body
    end

    result
  end

  # --- 폴백: 태그 기반 파싱 ---

  #: (String body) -> String
  def clean_body(body)
    body = strip_leading_ai_preamble(body)
    body = strip_leading_humanize_metadata(body)
    body = strip_trailing_humanize_metadata(body)
    body = strip_trailing_tags(body)
    body.strip
  end

  #: (String text) -> String
  def extract_body_fallback(text)
    text = strip_tagged_blocks(text, "SUMMARY_KEY")
    text = strip_summary_detail_blocks(text)
    text = text.gsub(/<<<SUMMARY_BODY>>>{0,1}\s*/m, "").gsub(/\s*<<<END_SUMMARY_BODY>>>{0,1}/m, "")
    text = strip_leading_ai_preamble(text)
    text = strip_leading_humanize_metadata(text)
    text = strip_trailing_humanize_metadata(text)
    text = strip_trailing_tags(text)
    text.strip
  end

  #: (untyped content, String tag) -> String?
  def extract_tagged_block(content, tag)
    escaped_tag = Regexp.escape(tag)
    match = content.to_s.match(%r{<<<#{escaped_tag}>>>\s*(.+?)\s*<<<END_#{escaped_tag}>>>{0,1}}m)
    match && match[1].strip
  end

  #: (untyped content) -> Array[String]
  def extract_summary_key(content)
    block = extract_tagged_block(content, "SUMMARY_KEY")
    return [] if block.blank?

    block.lines.filter_map do |line|
      item = line.sub(/\A\s*[-*]\s*/, "").strip
      item.presence
    end
  end

  #: (untyped content) -> Hash[String, String]
  def extract_summary_detail(content)
    detail_keys = content.to_s.scan(/<<<SUMMARY_DETAIL:([^>]+)>>>/).flatten.uniq
    detail_keys.each_with_object({}) do |key, detail|
      block = extract_tagged_block(content, "SUMMARY_DETAIL:#{key}")
      detail[key] = block if block.present?
    end
  end

  #: (String text) -> String
  def strip_leading_ai_preamble(text)
    match = text.match(/\A.*?(?=###\s)/m)
    if match && match[0].strip.present?
      preamble = match[0].strip
      text.sub(/\A#{Regexp.escape(preamble)}/m, "") if preamble.length < text.length / 2
    else
      text
    end
  end

  #: (String text) -> String
  def strip_trailing_tags(text)
    text.gsub(/\s*<<<\/?END?_?SUMMARY[^>]*>>>{0,1}/m, "")
  end

  #: (String text) -> String
  def strip_leading_humanize_metadata(text)
    cleaned = text.sub(/\A```(?:[\w-]*)\s*\nhumanize-korean[^\n]*\n```\s*/m, "")
    cleaned = cleaned.sub(/\Ahumanize-korean\s+v[\d.]+\s+—.*?\n+/m, "")
    cleaned.sub(/\A---\s*\n+/m, "")
  end

  #: (String text) -> String
  def strip_trailing_humanize_metadata(text)
    cleaned = text.sub(/\n+##\s*요약\b.*\z/m, "")
    cleaned = cleaned.sub(/\n+###\s*(?:탐지·처방 내역|자체검증)\b.*\z/m, "")
    cleaned = cleaned.sub(/\n+\|\s*항목\s*\|\s*내용\s*\|.*\z/m, "")
    cleaned.sub(/\n+>\s*원문이 기술 리포트.*\z/m, "")
  end

  #: (String content, String tag) -> String
  def strip_tagged_blocks(content, tag)
    escaped_tag = Regexp.escape(tag)
    content.gsub(%r{<<<#{escaped_tag}>>>\s*.*?\s*<<<END_#{escaped_tag}>>>}m, "")
  end

  #: (String content) -> String
  def strip_summary_detail_blocks(content)
    content.gsub(%r{<<<SUMMARY_DETAIL:[^>]+>>>\s*.*?\s*<<<END_SUMMARY_DETAIL:[^>]+>>>}m, "")
  end
end
