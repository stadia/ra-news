# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class KnowledgeAgent < ApplicationAgent
    description "메타데이터 추출 및 지식 구조 설계"
    model "gemini-3-flash-preview"

    param :cleaned_content, required: true
    param :semantic_chunks, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        object :global_context do
          string :title, description: "제목"
          string :source_type, description: "문서 유형: article, blog, video"
          string :summary_goal, description: "요약 목적"
          string :lead_paragraph, description: "서론"
          array :entities, of: :string, description: "핵심 키워드 목록"
          array :tags, of: :string, description: "태그 (최대 3개, snake_case)"
        end
        object :knowledge_architecture, description: "지식 구조" do
          string :core_message, description: "핵심 메시지 (한 문장)"
          array :key_points, of: :string, description: "주요 포인트 (3-5개)"
          string :why_it_matters, description: "중요성"
          string :target_audience, description: "대상 독자"
          array :practical_takeaways, of: :string, description: "실용적 시사점"
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        Ruby 기술 콘텐츠 분석가 겸 지식 설계자

        [Goal]
        청크들을 통합 분석하여 글로벌 맥락(제목, 유형, 목적, 엔티티, 태그)을 정의하고, 독자가 빠르게 가치를 파악할 수 있는 지식 구조를 추출

        [Rules]
        - Language Policy: 분석 결과는 원문(영어)의 기술 용어와 문장 구조를 유지
        - 지식의 위계 설정: 문서 전체를 관통하는 global_context를 정의하고 핵심 entities 식별
        - 기술 설계 분석: Ruby 성능, 자원 관리, 라이브러리 호환성에 미치는 영향 분석
        - 생태계 맵핑: Ruby 철학과의 정렬도 및 커뮤니티 예상 반응을 아키텍트 시각에서 설계

        [Tag Extraction Rules]
        - 형식: 최대 3개, snake_case (예: solid_queue, rails_8)
        - 우선순위: 핵심 기술/젬 이름 > 구체적 버전 > 주요 개념/패턴
        - 제외: ruby, rails, web_development, programming 등 일반 키워드
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 정제된 기술 콘텐츠를 분석하여 **지식 설계도(Knowledge Architecture)**를 작성하십시오.

        #{prepare_input_for_architect}
      PROMPT
    end

    # Data Prepper가 만든 청크들을 합쳐서 Architect에게 전달
    def prepare_input_for_architect
      # 청크들을 순서대로 마크다운으로 변환
      semantic_chunks.map do
        "### #{it['heading']}\n#{it['content']}"
      end.join("\n\n")
    end
  end
end
