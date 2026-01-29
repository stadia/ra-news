# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # TechnicalWriterAgent - 마크다운 본론 작성
  #
  # 기사의 본론(body)을 구조화된 마크다운으로 작성합니다.
  # 핵심 요약과 컨텍스트를 바탕으로 상세한 설명을 생성합니다.
  #
  # @example
  #   result = Articles::TechnicalWriterAgent.call(
  #     content: "원본 콘텐츠...",
  #     summary_key: ["핵심1", "핵심2", "핵심3"],
  #     context: "배경 정보...",
  #     title: "기사 제목"
  #   )
  #   result.content[:summary_body] # 마크다운 본문
  #
  class TechnicalWriterAgent < ApplicationAgent
    description "기사 본론 마크다운 작성"
    version "1.0"

    # 더 강력한 모델, 창의적 작문 허용
    model "gemini-2.5-flash"
    temperature 0.6
    timeout 120

    param :content, required: true
    param :summary_key, required: true  # Array of 3 key points
    param :context, default: nil        # Background context from ContextProviderAgent
    param :title, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :summary_body, description: "마크다운 형식의 본론 (400-800자)"

        array :sections, description: "본론의 섹션 구조" do
          object do
            string :heading, description: "섹션 제목"
            string :content_type, description: "섹션 유형 (explanation, code, comparison, list)"
          end
        end

        boolean :includes_code, description: "코드 예제 포함 여부"
        integer :word_count, description: "본론 글자 수"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        #{korean_ruby_expert_prompt}

        ## 역할
        당신은 Ruby 전문 기술 작가입니다. 복잡한 기술 콘텐츠를 명확하고 구조화된 마크다운으로 작성합니다.

        ## 본론 (summary_body) 작성 규칙

        ### 구조
        - 400-800자 (한국어 기준)
        - 2-4개의 논리적 섹션으로 구성
        - 각 섹션은 명확한 헤더 사용 (## 또는 ###)
        - 복잡한 내용은 목록으로 정리

        ### 마크다운 포맷
        - 헤더: ## 또는 ### 사용 (# 사용 금지)
        - 강조: **굵게** 또는 *이탤릭*
        - 목록: - 또는 1. 사용
        - 코드: 인라인 `code` 또는 코드 블록 ```ruby```
        - 링크는 제외 (별도 처리)

        ### 코드 예제
        - 원본에 코드가 있으면 핵심 부분만 발췌
        - 코드 블록에 언어 태그 필수 (```ruby)
        - 불필요한 코드는 생략
        - 주석으로 핵심 설명 추가 가능

        ### 내용 작성 원칙
        - 핵심 요약(summary_key)을 확장하되 반복하지 않음
        - 원본 콘텐츠의 핵심 내용 충실히 전달
        - Ruby 개발자 관점에서 실용적 정보 강조
        - 추상적 설명보다 구체적 사례/수치 선호

        ### 피해야 할 것
        - 인사말, 마무리 문구 (서론/결론에서 처리)
        - 원본에 없는 정보 추가
        - 과도한 기술 용어 설명 (링크로 대체 가능)
        - 문단이 너무 길어지는 것

        ## 섹션 유형
        - explanation: 개념/기능 설명
        - code: 코드 예제 중심
        - comparison: 비교 (이전 버전, 대안 등)
        - list: 목록 형식 나열

        ## 품질 체크리스트
        1. 각 섹션이 명확한 목적을 가지는가?
        2. 핵심 요약을 뒷받침하는가?
        3. Ruby 개발자에게 실질적 가치가 있는가?
        4. 마크다운 문법이 올바른가?
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 정보를 바탕으로 기사 본론을 마크다운으로 작성해주세요.

        ## 제목
        #{title}

        ## 핵심 요약 (이 내용을 확장)
        #{formatted_summary_key}

        #{context_section}

        ## 원본 콘텐츠
        #{truncated_content}
      PROMPT
    end

    # @rbs return: String
    def formatted_summary_key #: String
      Array(summary_key).map.with_index { |point, i| "#{i + 1}. #{point}" }.join("\n")
    end

    # @rbs return: String
    def context_section #: String
      return "" if context.blank?

      <<~SECTION
        ## 배경 정보
        #{context}
      SECTION
    end

    # @rbs return: String
    def truncated_content #: String
      content.to_s.truncate(10_000, omission: "\n\n[... 이하 생략 ...]")
    end
  end
end
