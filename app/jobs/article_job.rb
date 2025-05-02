# frozen_string_literal: true

# rbs_inline: enabled

class ArticleJob < ApplicationJob
  queue_as :default

  #: (id int) -> void
  def perform(id)
    article = Article.find_by(id: id)
    return unless article.is_a?(Article)

    prompt = <<~PROMPT
제공한 링크의 본문을 주의 깊게 읽고 요약, 정리 한 내용을 한국어로 제공합니다.
간단한 핵심 요약과 상세 요약을 제공합니다. 요약, 정리를 하기 위해 다른 사이트를 참고 해야 할 수 있습니다.
핵심 요약은 3줄 이내로 작성합니다.
상세 요약은 주요 내용(main_content)과 결론(conclusion)의 형식으로 작성합니다.
출력 결과는 파싱하기 쉽도록 JSON 형태로 제목(title_ko), 핵심 요약(summary_key), 상세 요약(summary_detail) 세 항목을 출력합니다.
    PROMPT

    chat = RubyLLM.chat
    chat.with_instructions("You are a Ruby land and RubyOnRails framework expert.")
    response = chat.ask("#{prompt} #{article.url}")
    # logger.debug response.content

    # JSON 데이터 추출 및 파싱
    json_string = response.content.match(/\{.*\}/m).to_s # 첫 번째 JSON 객체만 추출
    parsed_json = JSON.load(json_string) # JSON 파싱
    # JSON 데이터 저장
    article.update(parsed_json.slice("summary_key", "summary_detail", "title_ko"))
    # JSON 데이터 저장
  end
end
