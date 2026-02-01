# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class KnowledgeAgent < ApplicationAgent
    description "기사의 글로벌 맥락과 엔티티를 뽑아내며 설계도를 생성"
    version "1.0"

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
        end
        object :knowledge_architecture, description: "Ruby 생태계 관점의 지식 설계도" do
          object :technical_design do
            string :core_abstraction, description: "기술적 추상화"
            string :performance_impact, description: "성능 영향"
          end
          object :ecosystem_map do
            array :dependency_landscape, of: :string
            string :philosophical_alignment
            array :key_debates, of: :string, description: "논쟁 지점"
          end
          object :implementation_guide do
            string :strategic_value, description: "전략적 가치"
            array :immediate_actions, of: :string
          end
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]

        당신은 15년 차 Ruby 소프트웨어 아키텍트입니다. 정제된 텍스트 청크를 바탕으로 지식의 위계(Hierarchy)를 세우고 전략적 맥락을 설계합니다.

        [Mission]

        1. 청크들을 통합 분석하여 문서의 **글로벌 맥락(제목, 유형, 목적, 엔티티)**을 정의하십시오.
        2. Ruby 생태계 관점에서 기술적/철학적 가치를 추출하여 지식 설계도를 완성하십시오.

        [Instructions]

        1. 당신은 '기술 콘텐츠 지능화 팀'의 지식 설계자입니다.
        2. Language Policy: 모든 분석 결과(core_abstraction, impact, debates 등)는 반드시 원문(영어)의 기술 용어와 문장 구조를 유지하여 작성하십시오.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task]#{' '}

        다음 정제된 기술 콘텐츠를 분석하여 Ruby 생태계 관점의 **지식 설계도(Knowledge Architecture)**를 작성하십시오.

        [Input]#{' '}

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
