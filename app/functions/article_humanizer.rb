# frozen_string_literal: true
# rbs_inline: enabled

module ArticleHumanizer
  module_function

  #: (Article article) -> String
  def prompt(article)
    <<~PROMPT
      /humanize
      다음 텍스트를 자연스러운 한국어로 윤문하라.
      응답에는 설명, 상태줄, 메타데이터, 코드 펜스, 구분선, 표를 포함하지 말고 아래 태그 블록만 그대로 유지하여 반환하라.
      각 태그의 이름과 순서는 절대 바꾸지 말고, 태그 사이의 내용만 윤문하라.
      원문의 의미와 마크다운 구조는 유지하라.

      <<<SUMMARY_KEY>>>
      #{format_summary_key(article.summary_key)}
      <<<END_SUMMARY_KEY>>>

      #{format_summary_detail_blocks(article.summary_detail)}

      <<<SUMMARY_BODY>>>
      #{article.summary_body}
      <<<END_SUMMARY_BODY>>>
    PROMPT
  end

  #: (untyped content) -> Hash[Symbol, untyped]
  def extract_content(content)
    text = content.to_s.strip

    {
      summary_key: extract_summary_key(text),
      summary_detail: extract_summary_detail(text),
      summary_body: extract_body(text)
    }
  end

  #: (untyped content) -> String
  def extract_body(content)
    body = extract_tagged_block(content, "SUMMARY_BODY") || content.to_s.strip
    return body if body.blank?

    body = extract_humanized_section(body)
    body = strip_leading_humanize_metadata(body)
    body = strip_trailing_humanize_metadata(body)
    body.strip
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
  def extract_humanized_section(text)
    match = text.match(/##\s*윤문 결과\s*(.+?)(?=\n---\s*\n|\n##\s*요약\b|\z)/m)
    match ? match[1].strip : text
  end

  #: (untyped content, String tag) -> String?
  def extract_tagged_block(content, tag)
    escaped_tag = Regexp.escape(tag)
    match = content.to_s.match(%r{<<<#{escaped_tag}>>>\s*(.+?)\s*<<<END_#{escaped_tag}>>>}m)
    match && match[1].strip
  end

  #: (untyped summary_key) -> String
  def format_summary_key(summary_key)
    Array(summary_key).map { |item| "- #{item}" }.join("\n")
  end

  #: (untyped summary_detail) -> String
  def format_summary_detail_blocks(summary_detail)
    summary_detail.to_h.map do |key, value|
      <<~BLOCK.strip
        <<<SUMMARY_DETAIL:#{key}>>>
        #{value}
        <<<END_SUMMARY_DETAIL:#{key}>>>
      BLOCK
    end.join("\n\n")
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
end
