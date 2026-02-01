# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class KnowledgeAgent < ApplicationAgent
    description "기사의 글로벌 맥락과 엔티티를 뽑아내며 설계도를 생성"
    version "1.0"
    model "gemini-3-flash-preview"

    param :cleaned_content, required: true
    param :semantic_chunks, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        object :global_context do
          string :title, description: "제목"
          string :source_type, description: "원본 문서 유형 (article, blog, video)"
          string :summary_goal, description: "요약 목적"
          string :lead_paragraph, description: "서론"
          array :entities, of: :string, description: "키워드/엔티티 목록"
          array :tags, of: :string, description: "핵심 태그 (최대 3개, snake_case)"
        end
        object :knowledge_architecture, description: "기사 핵심 구조" do
          string :core_message, description: "핵심 메시지 (한 문장)"
          array :key_points, of: :string, description: "주요 포인트 (3-5개)"
          string :why_it_matters, description: "왜 중요한가"
          string :target_audience, description: "대상 독자"
          array :practical_takeaways, of: :string, description: "실용적 시사점"
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]

        당신은 15년 차 Ruby 소프트웨어 아키텍트이자 기술 콘텐츠 전문가입니다. 기사의 핵심을 파악하고 독자에게 전달할 가치를 설계합니다.

        [Mission]

        1. 청크들을 통합 분석하여 문서의 **글로벌 맥락(제목, 유형, 목적, 엔티티, 태그)**을 정의하십시오.
        2. 기사의 핵심 구조를 추출하여 독자가 빠르게 가치를 파악할 수 있도록 정리하십시오.

        [Instructions]

        1. 당신은 '기술 콘텐츠 지능화 팀'의 지식 설계자입니다.
        2. Language Policy: 모든 분석 결과는 반드시 원문(영어)의 기술 용어와 문장 구조를 유지하여 작성하십시오.

        [Tag Extraction Rules]

        1. 형식: 최대 3개, snake_case (예: solid_queue, rails_8)
        2. 우선순위:
           - 핵심 기술/젬 이름 (sidekiq, postgresql, prism)
           - 구체적 버전 (rails_8, ruby_3_3)
           - 주요 개념/패턴 (active_record, hotwire, turbo)
        3. 제외 대상:
           - 일반적인 키워드: ruby, rails, web_development, programming
           - 너무 광범위한 용어: code, development, software
           - 문서에 직접 언급되지 않은 용어
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task]

        다음 정제된 기술 콘텐츠를 분석하여 Ruby 생태계 관점의 **지식 설계도(Knowledge Architecture)**를 작성하십시오.

        [Input]

        #{prepare_input_for_architect}

        [Instructions]

        1. 지식의 위계 설정: 위 마크다운의 제목과 내용을 바탕으로 문서 전체를 관통하는 global_context(제목, 유형, 목적, 리드 문구)를 정의하고 핵심 entities를 식별하십시오.
        2. 기술 설계 분석: 추출된 정보에서 Ruby 성능, 자원 관리, 라이브러리 호환성에 미치는 영향을 분석하십시오.
        3. 생태계 맵핑: Ruby 철학과의 정렬도 및 커뮤니티의 예상 반응(논쟁 지점)을 아키텍트의 시각에서 설계하십시오.
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
