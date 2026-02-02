# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class EditorOptimizerAgent < ApplicationAgent
    description "품질 평가 및 게시 승인 결정"
    version "1.0"

    temperature 0.2

    param :title, required: true
    param :title_ko, default: nil
    param :summary_key, required: true
    param :summary_body, required: true
    param :content, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        integer :quality_score, description: "품질 점수 (0-100)"
        boolean :approved, description: "게시 승인 여부"
        string :rejection_reason, description: "거부 사유 (거부 시에만)"
        object :quality_breakdown, description: "세부 평가" do
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
        Ruby 뉴스 플랫폼 수석 에디터

        [Goal]
        기사의 최종 품질을 검토하고 게시 승인 여부를 결정

        [Quality Criteria] (각 0-100)
        - relevance: Ruby 핵심(90+), 명확한 관련(70+), 간접 관련(50+), 낮음(~49)
        - completeness: 핵심 정보 포함도
        - readability: 구조화 및 명확성
        - accuracy: 기술적 정확성

        [Rules]
        - 승인 기준: quality_score >= 60 → approved = true
        - 거부 시 rejection_reason에 구체적 사유 명시
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
