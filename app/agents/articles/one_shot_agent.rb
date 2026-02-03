# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class OneShotAgent < ApplicationAgent
    description "원샷으로 모든 내용을 요약하고 정리합니다."
    version "1.0"
    model "gemini-3-flash-preview"
    temperature 0.6

    param :raw_content, required: true
    param :title, required: true
    param :url, required: true
    param :content_type, default: "html" # html, youtube, text

    def schema
      @schema ||= ArticleSchema.new
    end

    private

    # def messages
    #   [
    #     { role: :user, content: raw_content }
    #   ]
    # end

    def system_prompt
      <<~PROMPT
      주의 깊게 읽고 요약, 정리한 내용을 한국어로 제공합니다. 답변은 전문적인 어투로 작성하며, 주어진 내용에서 벗어나지 않도록 합니다.

      ## 출력 구조 및 요구사항

      ### 1. 핵심 요약 (summary_key)
      - 3개의 문자열 배열로 구성
      - 각 요약은 한 줄로 작성 (80자 이상)
      - 가장 중요한 내용 순으로 정렬

      ### 2. 상세 요약 (summary_detail)
      다음 3단 구조의 객체로 구성:
      - **introduction** (서론): 주제와 배경 설명 (200-300자)
      - **body** (본론): 핵심 내용과 세부사항 (1000자 이상)
      - **conclusion** (결론): 요약과 시사점 (200-300자)

      body(본론)은 markdown 형식으로 작성하되, 헤더와 글머리 기호를 적극 활용하여 가독성을 높입니다.

      ### 3. 태그 (tags)
      - 최대 3개의 문자열 배열
      - 본문에서 추출한 핵심 키워드 우선
      - ruby, rails, ruby on rails, web development 와 같은 일반적인 키워드는 무시
      - snake case 로 작성
      - 기술 용어는 원어 유지 (예: Rails, Ruby, Gem)
      - 일반 명사보다는 구체적 개념 우선

      ### 4. Ruby 관련성 판단 (is_related)
      다음 기준으로 true/false 판단:
      - **true**: Ruby 언어, Rails, Gem, Ruby 개발 도구, Ruby 커뮤니티 관련
      - **false**: 다른 프로그래밍 언어만 다루거나 Ruby와 직접적 연관 없음

      ## 입력 포맷 처리

      ### HTML 형식 텍스트 처리
      - 인라인 포맷(bold, italic, links)과 블록 요소(headings, lists, code blocks) 모두 고려
      - 구조화된 콘텐츠의 컨텍스트 보존
      - 중첩된 HTML 요소 적절히 처리

      #### YouTube 자막 처리
      - 필러 단어: 음, 어, 그, 저, 뭐랄까, 있잖아요
      - 반복 발화: 같은 단어/구절의 연속 반복
      - 자동 생성 자막의 인식 오류 (문맥상 명백한 경우)
      PROMPT
    end

    def user_prompt
      if content_type == "youtube"
        # YouTube URL인 경우
        logger.info "YoutubeContent url: #{url}"
        <<~PROMPT
        Youtube url과 Transcript를 활용하여 전문적인 기술 요약 아티클을 집필하십시오.
        url: #{url}
        title: #{title}
        transcript:
        #{raw_content}
        PROMPT
      else
        # YouTube URL이 아닌 경우
        logger.info "HtmlContent url: #{url})"
        <<~PROMPT
        url과 본문을 활용하여 전문적인 기술 요약 아티클을 집필하십시오.
        url: #{url}
        title: #{title}
        content:
        #{raw_content}
        PROMPT
      end
    end
  end
end
