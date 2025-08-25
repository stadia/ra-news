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

    if article.body.blank?
      body = ContentService.call(article)
      article.discard! and return if body.blank?

      article.update(body: body)
    end

    prompt = <<~PROMPT
주의 깊게 읽고 요약, 정리한 내용을 한국어로 제공합니다. 답변은 전문적인 어투로 작성하며, 주어진 내용에서 벗어나지 않도록 합니다.

## 출력 구조 및 요구사항

### 1. 핵심 요약 (summary_key)
- 3개의 문자열 배열로 구성
- 각 요약은 한 줄로 작성 (200자 이내)
- 가장 중요한 내용 순으로 정렬

### 2. 상세 요약 (summary_detail)
다음 3단 구조의 객체로 구성:
- **introduction** (서론): 주제와 배경 설명 (200-300자)
- **body** (본론): 핵심 내용과 세부사항 (400-800자)
- **conclusion** (결론): 요약과 시사점 (200-300자)

body(본론)은 markdown 형식으로 작성하되, 헤더와 글머리 기호를 적극 활용하여 가독성을 높입니다.

### 3. 태그 (tags)
- 최대 3개의 문자열 배열
- 본문에서 추출한 핵심 키워드 우선
- ruby, rails, ruby on rails, web development 와 같은 일반적인 키워드는 무시
- 공백은 _ 로 대체
- 기술 용어는 원어 유지 (예: Rails, Ruby, Gem)
- 일반 명사보다는 구체적 개념 우선

### 4. Ruby 관련성 판단 (is_related)
다음 기준으로 true/false 판단:
- **true**: Ruby 언어, Rails, Gem, Ruby 개발 도구, Ruby 커뮤니티 관련
- **false**: 다른 프로그래밍 언어만 다루거나 Ruby와 직접적 연관 없음

## 입력 포맷 처리
- HTML 형식 텍스트 처리
- 인라인 포맷(bold, italic, links)과 블록 요소(headings, lists, code blocks) 모두 고려
- 구조화된 콘텐츠의 컨텍스트 보존
- 중첩된 HTML 요소 적절히 처리
PROMPT

    chat = RubyLLM.chat(model: "gemini-2.5-flash", provider: :gemini).with_temperature(0.6).with_schema(ArticleSchema)
    # chat = RubyLLM.chat(model: "google/gemma-3n-e4b", provider: :ollama, assume_model_exists: true).with_temperature(0.7)
    llm_instructions = "You are a professional developer of the Ruby programming language. On top of that, you are an excellent technical writer. All output should be in Korean."
    chat.with_instructions(llm_instructions)
    chat.add_message(role: :user, content: article.body)
    response =  if article.is_youtube?
      # YouTube URL인 경우
      logger.info "YoutubeContent url: #{article.url}, id: #{article.id})"
      chat.ask("YoutubeContent 로 제공한 url과 Transcript를 #{prompt} (url: #{article.url}, id: #{article.id})")
    else
      # YouTube URL이 아닌 경우
      logger.info "HtmlContent url: #{article.url}, id: #{article.id})"
      chat.ask("HtmlContent 로 제공한 url과 본문을 #{prompt} (url: #{article.url}, id: #{article.id})")
    end
    logger.info "Response received for article id: #{id}"

    # Generate embeddings if not present and body exists
    if article.embedding.blank? && article.body.present?
      begin
        embedded_body = RubyLLM.embed(
          article.body,
          model: "gemini-embedding-001", # Google's model
          dimensions: 1536 # 1536차원
        )
        article.update_column(:embedding, embedded_body.vectors.to_a) # Skip callbacks for performance
      rescue StandardError => e
        logger.error "Failed to generate embeddings for article #{id}: #{e.message}"
        # Continue processing without embeddings
      end
    end

    unless response.respond_to?(:content)
      article.discard
      return
    end

    logger.info "article id: #{id} Response content: #{response.content}"
    # JSON 데이터 추출 및 파싱
    parsed_json = response.content
    logger.debug parsed_json.inspect
    if parsed_json.blank? || parsed_json.empty?
      article.discard
      return
    end

    # JSON 데이터 저장
    article.tag_list.add(parsed_json["tags"].map { it.downcase }.uniq) if parsed_json["tags"].is_a?(Array)
    # Use ActiveRecord transaction for data consistency
    Article.transaction do
      # 매직 스트링 대신 Site.clients enum 사용
      if parsed_json["is_related"] == false && %w[hacker_news rss gmail rss_page].include?(article.site&.client)
        article.discard # `deleted_at = Time.zone.now` 대신 discard 사용
        return # Exit early if discarded
      end

      # Update article attributes in single query
      article.update!(parsed_json.slice("summary_key", "summary_detail", "title_ko", "is_related"))
    end

    # Rebuild search index only for kept articles
    PgSearch::Multisearch.rebuild(Article, clean_up: false, transactional: false) unless article.discarded?

    # Trigger Twitter posting after successful article processing
    TwitterPostJob.perform_later(article.id)
  end
end
