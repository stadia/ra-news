# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # TranslatorAgent - 제목 번역 (영/일 → 한)
  #
  # 영어 또는 일본어 제목을 한국어로 번역합니다.
  # 기술 용어는 적절히 유지하면서 자연스러운 한국어 제목을 생성합니다.
  #
  # @example
  #   result = Articles::TranslatorAgent.call(
  #     title: "Rails 8 Brings Solid Queue",
  #     content_preview: "Rails 8 introduces..."
  #   )
  #   result.content[:title_ko] # "Rails 8, Solid Queue 도입"
  #
  class TranslatorAgent < ApplicationAgent
    description "기사 제목 한국어 번역"
    version "1.0"

    # 번역은 약간의 창의성 허용
    temperature 0.3
    cache 24.hours

    param :title, required: true
    param :content_preview, default: nil # 맥락 파악용 본문 미리보기

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :title_ko, description: "한국어 번역 제목"
        string :original_language, description: "원본 언어 코드 (en, ja, ko, zh, etc.)"
        boolean :translation_needed, description: "번역 필요 여부"
        string :translation_note, description: "번역 시 고려사항 (있는 경우)"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        ## 역할
        당신은 기술 콘텐츠 전문 번역가입니다. Ruby 및 소프트웨어 개발 관련 제목을 자연스러운 한국어로 번역합니다.

        ## 번역 원칙

        ### 기술 용어 처리
        - 고유명사 유지: Ruby, Rails, PostgreSQL, Redis, AWS 등
        - 젬 이름 유지: Devise, Pundit, Sidekiq 등
        - 버전 표기 유지: "Rails 8.0", "Ruby 3.3" 등
        - 일반적인 기술 약어 유지: API, REST, GraphQL, CI/CD 등

        ### 번역 스타일
        - 간결하고 명확하게
        - 뉴스 헤드라인 스타일 (명사형 종결 선호)
        - 원문의 톤과 강조점 유지
        - 클릭베이트 표현 자제

        ### 번역 예시
        - "Rails 8 Released with Solid Queue" → "Rails 8 출시, Solid Queue 기본 탑재"
        - "How to Build APIs with Ruby" → "Ruby로 API 구축하기"
        - "Ruby 3.3 Performance Improvements" → "Ruby 3.3 성능 개선 사항"
        - "Why We Chose Rails Over Node" → "Node 대신 Rails를 선택한 이유"

        ### 언어 감지
        - en: 영어
        - ja: 일본어
        - ko: 한국어 (번역 불필요)
        - zh: 중국어
        - 기타 언어 코드는 ISO 639-1 사용

        ### 번역 불필요 조건
        - 이미 한국어인 경우
        - 기술 용어로만 구성된 경우 (예: "Ruby 3.3.0")
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 제목을 한국어로 번역해주세요.

        ## 원본 제목
        #{title}

        #{content_context}
      PROMPT
    end

    # @rbs return: String
    def content_context #: String
      return "" if content_preview.blank?

      <<~CONTEXT
        ## 참고 맥락 (본문 일부)
        #{content_preview.to_s.truncate(500)}
      CONTEXT
    end
  end
end
