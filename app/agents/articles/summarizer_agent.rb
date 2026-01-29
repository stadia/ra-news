# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # SummarizerAgent - 핵심 요약 3줄 + 서론/결론
  #
  # 기사의 핵심 내용을 3가지 포인트로 요약하고,
  # 서론(배경)과 결론(시사점)을 작성합니다.
  #
  # @example
  #   result = Articles::SummarizerAgent.call(
  #     content: "Rails 8의 새로운 기능...",
  #     title: "Rails 8 Released"
  #   )
  #   result.content[:summary_key] # ["핵심1", "핵심2", "핵심3"]
  #
  class SummarizerAgent < ApplicationAgent
    description "기사 핵심 요약 및 서론/결론 생성"
    version "1.0"

    # 더 강력한 모델 사용, 창의적 요약 허용
    model "gemini-2.5-flash"
    temperature 0.5
    timeout 90

    param :content, required: true
    param :title, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        array :summary_key, of: :string, description: "핵심 요약 3개 (중요도 순)"

        object :summary_partial, description: "부분 요약" do
          string :introduction, description: "서론 - 주제와 배경 (200-300자)"
          string :conclusion, description: "결론 - 요약과 시사점 (200-300자)"
        end

        string :content_type, description: "콘텐츠 유형 (tutorial, news, opinion, reference)"
        integer :estimated_read_time, description: "예상 읽기 시간 (분)"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        #{korean_ruby_expert_prompt}

        ## 역할
        당신은 Ruby 생태계 전문 기술 에디터입니다. 복잡한 기술 콘텐츠를 명확하고 간결하게 요약합니다.

        ## 핵심 요약 (summary_key) 작성 규칙

        ### 형식
        - 정확히 3개의 핵심 포인트
        - 각 포인트는 1문장, 200자 이내
        - 중요도 순으로 정렬 (가장 중요한 것이 첫 번째)

        ### 내용 기준
        - "무엇이 새롭거나 중요한가?" 중심
        - 구체적인 수치, 버전, 이름 포함 권장
        - 추상적 표현보다 구체적 사실
        - 독자가 본문을 읽지 않아도 핵심을 파악할 수 있게

        ### 예시
        - ❌ "성능이 개선되었다" → ✅ "Ruby 3.3에서 YJIT 활성화 시 30% 성능 향상"
        - ❌ "새로운 기능이 추가됐다" → ✅ "Solid Queue가 기본 백그라운드 잡 어댑터로 채택"

        ## 서론 (introduction) 작성 규칙
        - 200-300자
        - 이 콘텐츠가 다루는 주제와 배경 설명
        - 왜 이것이 Ruby 개발자에게 중요한지 맥락 제공
        - 독자의 관심을 끄는 도입부

        ## 결론 (conclusion) 작성 규칙
        - 200-300자
        - 핵심 내용 재정리
        - 실무적 시사점 또는 다음 단계 제시
        - Ruby 개발자가 얻을 수 있는 가치 강조

        ## 콘텐츠 유형 분류
        - tutorial: 단계별 가이드, How-to
        - news: 발표, 릴리즈, 뉴스
        - opinion: 의견, 분석, 회고
        - reference: 문서, 레퍼런스, 목록

        ## 읽기 시간 계산
        - 한국어 기준 분당 약 500자
        - 코드 블록은 2배로 계산
        - 최소 1분, 최대 30분
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 기사를 요약해주세요.

        ## 제목
        #{title}

        ## 본문
        #{content}
      PROMPT
    end
  end
end
