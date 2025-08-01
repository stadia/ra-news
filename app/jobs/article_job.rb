# frozen_string_literal: true

# rbs_inline: enabled

class ArticleJob < ApplicationJob
  queue_as :default

  #: (Integer id) -> void
  def perform(id)
    article = Article.kept.find_by(id: id)
    logger.info "ArticleJob started for article id: #{id}"
    unless article.is_a?(Article)
      logger.error "Article with id #{id} not found or has been discarded."
      return
    end

    prompt = <<~PROMPT
주의 깊게 읽고 요약, 정리 한 내용을 한국어로 제공합니다. 답변은 전문적인 어투로 작성하며, 주어진 내용에서 벗어나지 않도록 합니다.
간단한 핵심 요약과 상세 요약을 제공합니다. 요약, 정리를 하기 위해 또 다른 사이트나 문서를 참고 할 수 있습니다.
핵심 요약은 3줄 이내로 작성합니다.
상세 요약은 서론(introduction)-본론(body)-결론(conclusion)의 3단 구조를 기본으로 합니다. 상세 요약(summary_detail)은 800자 이상 1500자 이내로 작성합니다.
주요 태그(tags)를 최대 3개 추출합니다. 이 태그는 가급적 본문에 포함 된 단어를 사용하며 주제를 표현할 수 있는 핵심 키워드들입니다. 태그는 한국어로 번역하지 않아도 됩니다.
요약, 정리 후 주어진 내용이 진짜 Ruby Programming Language 와 관련이 있는지 확인해서 출력 결과에 is_related 키로 boolean 값으로 표시합니다.
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
3. 출력 예제
- JSON 형태로 출력하며, 다음과 같은 구조를 따릅니다
#{ArticleSchema.new.to_json}
PROMPT

    chat = RubyLLM.chat(model: "gemini-2.5-flash", provider: :gemini).with_temperature(0.6)
    # chat = RubyLLM.chat(model: "google/gemma-3n-e4b", provider: :ollama, assume_model_exists: true).with_temperature(0.7)
    llm_instructions = "You are a professional developer of the Ruby programming language. On top of that, you are an excellent technical writer. All output should be in Korean."
    # chat.with_schema(ArticleSchema)
    chat.with_instructions(llm_instructions)
    chat.with_tool(ArticleBodyTool.new)
    response =  if article.is_youtube?
      # YouTube URL인 경우
      article.update(body: YoutubeContentTool.new.execute(url: article.url)) if article.body.blank?
      logger.info "YoutubeContent url: #{article.url}, id: #{article.id})"
      chat.ask("YoutubeContent 로 제공한 url과 Transcript를 #{prompt} (url: #{article.url}, id: #{article.id})")
    else
      # YouTube URL이 아닌 경우
      article.update(body: HtmlContentTool.new.execute(url: article.url)) if article.body.blank?
      logger.info "HtmlContent url: #{article.url}, id: #{article.id})"
      chat.ask("HtmlContent 로 제공한 url과 본문을 #{prompt} (url: #{article.url}, id: #{article.id})")
    end
    logger.info "Response received for article id: #{id}"

    if article.embedding.blank?
      embedded_body = RubyLLM.embed(
        article.body,
        model: "gemini-embedding-001", # Google's model
        dimensions: 1536 # 1536차원
      )
      article.update(embedding: embedded_body.vectors.to_a)
    end

    unless response.respond_to?(:content)
      article.discard
      return
    end

    logger.info "article id: #{id} Response content: #{response.content}"
    # JSON 데이터 추출 및 파싱
    parsed_json = begin
                    JSON.parse(response.content.scan(/\{.*\}/m).first || "{}") # 첫 번째 JSON 객체만 추출하거나, 없으면 빈 JSON 객체
                  rescue JSON::ParserError => e
                    logger.error "JSON 파싱 오류: #{e.message} - 원본 응답: #{response.content}"
                    article.discard
                    return nil # 파싱 실패 시 nil 반환하여 이후 로직 중단
                  end
    # parsed_json = response.content
    logger.debug parsed_json.inspect
    if parsed_json.blank? || parsed_json.empty?
      article.discard
      return
    end

    # JSON 데이터 저장
    article.tag_list.add(parsed_json["tags"]) if parsed_json["tags"].is_a?(Array)
    # 매직 스트링 대신 Site.clients enum 사용
    if parsed_json["is_related"] == false && %w[hacker_news rss gmail rss_page].include?(article.site&.client)
      article.discard # `deleted_at = Time.zone.now` 대신 discard 사용
    end
    article.update(parsed_json.slice("summary_key", "summary_detail", "title_ko", "is_related"))
    PgSearch::Multisearch.rebuild(Article, clean_up: false, transactional: false)
    # PgSearch::Multisearch.rebuild(Article, transactional: false)

    # Trigger Twitter posting after successful article processing
    TwitterPostJob.perform_later(article.id)
  end
end
