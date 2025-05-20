# frozen_string_literal: true

# rbs_inline: enabled

class ArticleJob < ApplicationJob
  queue_as :default

  #: (id int) -> void
  def perform(id)
    article = Article.find_by(id: id)
    return unless article.is_a?(Article)

    prompt = <<~PROMPT
주의 깊게 읽고 요약, 정리 한 내용을 한국어로 제공합니다.
간단한 핵심 요약과 상세 요약을 제공합니다. 요약, 정리를 하기 위해 또 다른 사이트나 문서를 참고 할 수 있습니다.
핵심 요약은 3줄 이내로 작성합니다.
상세 요약은 서론(introduction)-본론(body)-결론(conclusion)의 3단 구조를 기본으로 합니다. 상세 요약은 800자 이상 1600자 이내로 작성합니다.
1. 입력 포맷
- Expect Markdown-formatted text
- Process both inline formatting (bold, italic, links) and block elements (headings, lists, code blocks)
- Preserve the context of structured content
- Handle nested Markdown elements appropriately
2. 출력 결과
- JSON 형태로 제목(title_ko), 핵심 요약(summary_key), 상세 요약(summary_detail) 세 항목을 출력합니다.
- 상세 요약은 markdown 형식으로 작성합니다.
- 출력 예제
{
  "title_ko": "",
  "summary_key": [
    "",
    "",
    ""
  ],
  "summary_detail": { "introduction": "", "body": "", "conclusion": "" }
}
PROMPT

    chat = RubyLLM.chat(model: "gemini-2.5-flash-preview-04-17", provider: :gemini, assume_model_exists: true)
    chat.with_instructions("You are a Ruby programming lang and RubyOnRails framework expert. Be precise and concise. Use OREO technique, pyramid structure, and transition expressions actively.")
    response =  if article.is_youtube?
      # YouTube URL인 경우
      transcript = article.youtube_transcript
      transcript.nil? ? nil : chat.ask("제공한 유튜브의 링크와 자막을 #{prompt} #{article.url}\n#{transcript}")
    else
      # YouTube URL이 아닌 경우
      logger.debug "제공한 링크의 본문을 #{prompt} #{markdown(article.url)}"
      chat.ask("제공한 본문을 #{prompt} #{markdown(article.url)}")
    end

    unless response.respond_to?(:content)
      article.update(deleted_at: Time.zone.now)
      return
    end

    logger.debug response.content
    # JSON 데이터 추출 및 파싱
    json_string = response.content.match(/\{.*\}/m).to_s # 첫 번째 JSON 객체만 추출
    parsed_json = JSON.load(json_string) # JSON 파싱
    if parsed_json.blank? || parsed_json.empty?
      article.update(deleted_at: Time.zone.now)
      return
    end

    # JSON 데이터 저장
    article.update(parsed_json.slice("summary_key", "summary_detail", "title_ko"))
    SitemapJob.perform_later
  end

  private

  #: (url string) -> string
  def markdown(url)
    response = Faraday.get(url)
    html_content = response.body
    return "" if html_content.blank?

    # Readability를 사용하여 주요 콘텐츠 HTML 추출
    # Readability::Document는 전체 HTML 문자열을 인자로 받습니다.
    main_article_html = Readability::Document.new(html_content).content
    return "" if main_article_html.blank? # 주요 내용이 없으면 빈 문자열 반환

    # 추출된 주요 콘텐츠 HTML을 Markdown으로 변환
    Kramdown::Document.new(main_article_html, input: "html", auto_ids: false).to_kramdown
  end
end
