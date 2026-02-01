# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # EditorOptimizerAgent - 태그 추출 및 최종 편집
  #
  # 기사의 최종 품질을 검토하고 태그를 추출합니다.
  # 게시 승인 여부를 결정합니다.

  class EditorOptimizerAgent < ApplicationAgent
    description "기사 태그 추출 및 최종 품질 검토"
    version "1.0"

    # 결정론적 분석을 위해 낮은 temperature
    temperature 0.2

    param :title, required: true
    param :title_ko, default: nil
    param :summary_key, required: true
    param :summary_body, required: true
    param :content, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        array :tags, of: :string, description: "핵심 태그 (최대 3개, snake_case)"

        integer :quality_score, description: "품질 점수 (0-100)"

        boolean :approved, description: "게시 승인 여부"

        string :rejection_reason, description: "거부 사유 (거부 시에만)"

        object :quality_breakdown, description: "품질 세부 평가" do
          integer :relevance, description: "Ruby 관련성 (0-100)"
          integer :completeness, description: "내용 완성도 (0-100)"
          integer :readability, description: "가독성 (0-100)"
          integer :accuracy, description: "정확성 (0-100)"
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        ## 역할
        당신은 Ruby 뉴스 플랫폼의 수석 에디터입니다.
        기사의 최종 품질을 검토하고 게시 여부를 결정합니다.

        ## 태그 추출 규칙

        ### 형식
        - 최대 3개
        - snake_case 사용 (예: solid_queue, rails_8)
        - 영어 또는 영어화된 기술 용어

        ### 우선순위
        1. 핵심 기술/젬 이름 (rails, sidekiq, postgresql)
        2. 구체적 버전 (rails_8, ruby_3_3)
        3. 주요 개념/패턴 (active_record, hotwire, turbo)

        ### 제외 대상
        - 일반적인 키워드: ruby, rails, web_development, programming
        - 너무 광범위한 용어: code, development, software
        - 문서에 직접 언급되지 않은 용어

        ## 품질 평가 기준

        ### relevance (Ruby 관련성)
        - 90-100: Ruby 핵심 주제
        - 70-89: Ruby 관련이 명확
        - 50-69: 간접적 관련
        - 0-49: 관련성 낮음

        ### completeness (내용 완성도)
        - 90-100: 모든 핵심 정보 포함
        - 70-89: 대부분의 정보 포함
        - 50-69: 일부 정보 누락
        - 0-49: 불완전

        ### readability (가독성)
        - 90-100: 명확하고 잘 구조화됨
        - 70-89: 대체로 읽기 좋음
        - 50-69: 개선 여지 있음
        - 0-49: 읽기 어려움

        ### accuracy (정확성)
        - 90-100: 기술적으로 정확
        - 70-89: 대부분 정확
        - 50-69: 일부 오류 가능성
        - 0-49: 검증 필요

        ## 승인 기준
        - approved = true: quality_score >= 60
        - approved = false: quality_score < 60

        ### 거부 사유 예시
        - "Ruby와의 관련성이 부족합니다"
        - "내용이 너무 짧거나 불완전합니다"
        - "기술적 정확성 검증이 필요합니다"
        - "요약이 원본 내용을 충분히 반영하지 못합니다"
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 기사의 최종 검토를 수행해주세요.

        ## 원본 제목
        #{title}

        #{title_ko}

        ## 핵심 요약
        #{formatted_summary_key}

        ## 본론
        #{summary_body}

        ## 원본 콘텐츠 (참고용)
        #{truncated_content}
      PROMPT
    end

    # @rbs return: String
    def formatted_summary_key #: String
      Array(summary_key).map.with_index { |point, i| "#{i + 1}. #{point}" }.join("\n")
    end

    # @rbs return: String
    def truncated_content #: String
      content.to_s.truncate(4000, omission: "\n\n[... 이하 생략 ...]")
    end
  end
end
