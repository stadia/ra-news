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
상세 요약은 서론(introduction)-본론(body)-결론(conclusion)의 3단 구조를 기본으로, 문단 간 연결어와 논리 전개 유지형 요약, OREO 기법, 피라미드 구조 및 전환 표현을 적극 활용합니다. 상세 요약은 500자 이상 1000자 이내로 작성합니다.
출력 결과는 JSON 형태로 제목(title_ko), 핵심 요약(summary_key), 상세 요약(summary_detail) 세 항목을 출력합니다.
출력 예제
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

    chat = RubyLLM.chat
    chat.with_instructions("You are a Ruby programming lang and RubyOnRails framework expert.")
    response =  if article.is_youtube?
      # YouTube URL인 경우
      transcript = article.youtube_transcript
      chat.ask("제공한 유튜브의 링크와 자막을 #{prompt} #{article.url} #{transcript}")
    else
      # YouTube URL이 아닌 경우
      logger.debug "제공한 링크의 본문을 #{prompt} #{article.url}"
      chat.ask("제공한 링크의 본문을 #{prompt} #{article.url}")
    end
    logger.debug response.content

    # JSON 데이터 추출 및 파싱
    json_string = response.content.match(/\{.*\}/m).to_s # 첫 번째 JSON 객체만 추출
    parsed_json = JSON.load(json_string) # JSON 파싱
    # JSON 데이터 저장
    article.update(parsed_json.slice("summary_key", "summary_detail", "title_ko"))
    # JSON 데이터 저장
  end
end
