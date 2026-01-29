# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # DataPrepperAgent - 데이터 전처리 및 노이즈 제거
  #
  # HTML/YouTube 콘텐츠에서 불필요한 요소를 제거하고 깨끗한 텍스트를 추출합니다.
  #
  # @example
  #   result = Articles::DataPrepperAgent.call(
  #     raw_content: "<html>...</html>",
  #     content_type: "html"
  #   )
  #   result.content[:cleaned_content] # 정제된 콘텐츠
  #
  class DataPrepperAgent < ApplicationAgent
    description "기사 콘텐츠 전처리 및 노이즈 제거"
    version "1.0"

    # 기본 모델 설정 상속 (gemini-2.0-flash, temp 0.0)
    cache 6.hours

    param :raw_content, required: true
    param :content_type, default: "html" # html, youtube, text

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :cleaned_content, description: "정제된 콘텐츠 (노이즈 제거됨)"
        integer :original_length, description: "원본 콘텐츠 길이 (문자 수)"
        integer :cleaned_length, description: "정제된 콘텐츠 길이 (문자 수)"
        array :removed_elements, of: :string, description: "제거된 요소 유형 목록"
        string :content_quality, description: "콘텐츠 품질 평가 (high, medium, low)"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        #{korean_ruby_expert_prompt}

        ## 역할
        당신은 웹 콘텐츠 전처리 전문가입니다. 주어진 콘텐츠에서 핵심 내용만 추출하고 노이즈를 제거합니다.

        ## 처리 규칙

        ### HTML 콘텐츠
        - 네비게이션, 푸터, 사이드바, 광고 영역 제거
        - 소셜 공유 버튼, 구독 폼, 쿠키 동의 배너 제거
        - 댓글 섹션 제거 (본문과 무관)
        - 인라인 스타일, 스크립트 태그 제거
        - 의미 있는 본문 콘텐츠만 유지

        ### YouTube 자막
        - 타임스탬프 정보는 필요시 유지
        - 자동 생성 자막의 오류 교정
        - [음악], [박수] 같은 비언어적 표시 적절히 처리
        - 반복되는 문구 제거

        ### 공통 규칙
        - 코드 블록은 반드시 보존
        - 기술 용어와 고유명사 유지
        - 링크 텍스트 중 유의미한 것은 보존
        - 빈 줄이나 과도한 공백 정리

        ## 품질 평가 기준
        - high: 명확한 구조, 충분한 기술적 내용
        - medium: 읽을 수 있으나 일부 노이즈 존재
        - low: 내용이 부족하거나 품질 문제 있음
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 #{content_type_description} 콘텐츠를 분석하고 정제해주세요.

        ## 원본 콘텐츠
        #{raw_content}
      PROMPT
    end

    # @rbs return: String
    def content_type_description #: String
      case content_type.to_s
      when "html" then "HTML"
      when "youtube" then "YouTube 자막"
      else "텍스트"
      end
    end
  end
end
