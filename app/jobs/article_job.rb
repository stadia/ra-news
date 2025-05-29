# frozen_string_literal: true

# rbs_inline: enabled

class ArticleJob < ApplicationJob
  queue_as :default

  #: (id int) -> void
  def perform(id)
    article = Article.find_by(id: id)
    return unless article.is_a?(Article)

    prompt = <<~PROMPT
주의 깊게 읽고 요약, 정리 한 내용을 한국어로 제공합니다. 답변은 전문적인 어투로 작성하며, 주어진 내용에서 벗어나지 않도록 합니다.
간단한 핵심 요약과 상세 요약을 제공합니다. 요약, 정리를 하기 위해 또 다른 사이트나 문서를 참고 할 수 있습니다.
핵심 요약은 3줄 이내로 작성합니다.
상세 요약은 서론(introduction)-본론(body)-결론(conclusion)의 3단 구조를 기본으로 합니다. 상세 요약(summary_detail)은 800자 이상 1500자 이내로 작성합니다.
주요 태그를 최대 3개 추출합니다. 이 태그는 가급적 본문에 포함 된 단어를 사용하며 주제를 표현할 수 있는 핵심 키워드들입니다. 태그는 한국어로 번역하지 않아도 됩니다.
1. 입력 포맷
- Expect HTML-formatted text
- Process both inline formatting (bold, italic, links) and block elements (headings, lists, code blocks)
- Preserve the context of structured content
- Handle nested HTML elements appropriately
2. 출력 결과
- 핵심 내용 위주로 정보를 제공하고, 불필요한 내용은 생략합니다.
- JSON 형태로 제목(title_ko), 핵심 요약(summary_key), 상세 요약(summary_detail), 키워드(tags) 세 항목을 출력합니다.
- 주요 키워드를 제공합니다.
- 상세 요약은 요약된 내용을 보기 쉽고 이해하기 쉬운 markdown 형식으로 제공합니다.
- 출력 예제
```json
{
  "title_ko": "",
  "summary_key": ["", "", ""],
  "summary_detail": { "introduction": "", "body": "", "conclusion": "" },
  "tags": ["", "", ""]
}
```
PROMPT

    chat = RubyLLM.chat(model: "gemini-2.5-flash-preview-05-20", provider: :gemini, assume_model_exists: true)

    chat.with_instructions("You are an expert in the Ruby programming language and RubyOnRails framework. You are precise and concise. Use OREO technique, pyramid structure, and transition expressions actively. All output should be in Korean.")
    response =  if article.is_youtube?
      # YouTube URL인 경우
      chat.with_tool(YoutubeContentTool.new)
      chat.ask("YoutubeContent 로 제공한 url과 Transcript를 #{prompt} (url: #{article.url})")
    else
      # YouTube URL이 아닌 경우
      chat.with_tool(HtmlContentTool.new)
      chat.ask("HtmlContent 로 제공한 url과 본문을 #{prompt} (url: #{article.url})")
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
    article.tag_list.add(parsed_json["tags"]) if parsed_json["tags"].is_a?(Array)
    article.update(parsed_json.slice("summary_key", "summary_detail", "title_ko"))
    SitemapJob.perform_later
  end
end
