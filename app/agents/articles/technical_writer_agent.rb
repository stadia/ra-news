# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class TechnicalWriterAgent < ApplicationAgent
    description "기사 본론 마크다운 작성"
    version "1.0"
    model "gemini-3-flash-preview"

    # 더 강력한 모델, 창의적 작문 허용
    temperature 0.6
    timeout 120

    param :title, required: true
    param :semantic_chunks, required: true
    param :knowledge_architecture, required: true
    param :global_context, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        array :summary_key, of: :string, description: "3줄 요약 키워드"
        object :summary_detail do
          string :introduction, description: "서론"
          string :conclusion, description: "결론"
        end
        string :summary_body, description: "마크다운 형식의 본론"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]

        당신은 복잡한 기술 백서를 단 몇 줄의 핵심 메시지로 압축하고, 이를 다시 완결성 있는 아티클로 풀어내는 데 특화된 전문 작가입니다. 당신의 목표는 독자가 글을 읽기 시작한 지 10초 만에 가치를 느끼게 하고, 끝까지 읽었을 때 기술적 의사결정을 내릴 수 있도록 돕는 것입니다.

        [Instructions]

        1. 당신은 '기술 콘텐츠 지능화 팀'의 수석 기술 작가입니다.
        2. 구조적 집필: 모든 글은 서론-본론-결론의 구조를 따릅니다.
        3. 지식의 합성: Knowledge Architect의 기술적 깊이와 Context Provider의 전략적 통찰을 자연스럽게 융합하십시오.
        4. 전문적 톤: 시니어 루비 개발자가 읽기에 적합한 건조하면서도 통찰력 있는(Insightful) 문체를 유지하십시오.
        5. 언어: 모든 내용은 **영문(English)**으로 작성하십시오. (이후 단계에서 전문 번역가가 처리할 예정입니다.)
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task]

        제공된 지식 설계도를 구조로 삼고, **정제된 본문(Chunks)**의 세부 내용을 활용하여 전문적인 기술 요약 아티클을 집필하십시오.

        [Input]

        Title: #{title}

        Global Context:

        #{format_global_context}

        Key Entities: #{format_entities}

        Tags: #{format_tags}

        Architecture Blueprint:

        #{format_knowledge_architecture}

        Detailed Chunks:

        #{prepare_input_for_writer}

        [Writing Requirements]

        1. 내용의 구체성 (Detailing):

          * Architecture Blueprint에서 정의된 핵심 개념(core_abstraction)을 설명할 때, Detailed Chunks에 포함된 실제 설명과 코드 예시를 반드시 인용하여 구체성을 높이십시오.
          * 추상적인 서술에 그치지 말고, 청크에 나타난 기술적 디테일을 본문에 녹여내십시오.

        2. 핵심 요약 (summary_key):

          * 3개 요약을 작성합니다.
          * 가장 중요한 내용 순으로 정렬합니다.
          * 각 요약은 100자 이상의 하나의 완성된 문장으로 작성하십시오.

        3. 상세 요약 (summary_detail):

          * **introduction** (서론): global_context를 바탕으로 독자의 관심을 유도하면서 주제와 배경 설명을 제공하여 기사의 목적을 명확히 전달하십시오.
          * **body** (본론): 설계도의 위계를 따르되, 청크의 내용을 바탕으로 기술적 깊이가 느껴지도록 핵심 내용과 세부사항을 서술한다.
          * **conclusion** (결론): 요약과 시사점으로 글을 마무리 합니다.

        4. 키워드 활용 (Keyword Integration):

          * Key Entities와 Tags에 나열된 핵심 기술 용어를 본문에서 자연스럽게 언급하십시오.
          * 이 키워드들이 기사의 핵심 주제임을 독자가 인지할 수 있도록 강조하십시오.
      PROMPT
    end

    def prepare_input_for_writer
      # 청크들을 순서대로 마크다운으로 변환
      semantic_chunks.map do
        "### #{it['heading']}\n#{it['content']}"
      end.join("\n\n")
    end

    # @rbs return: String
    def format_knowledge_architecture #: String
      format_as_markdown(knowledge_architecture)
    end

    # @rbs return: String
    def format_global_context #: String
      format_as_markdown(global_context)
    end

    # @rbs return: String
    def format_entities #: String
      extract_array_from_context(:entities).join(", ")
    end

    # @rbs return: String
    def format_tags #: String
      extract_array_from_context(:tags).join(", ")
    end

    # @rbs (Symbol) -> Array[String]
    def extract_array_from_context(key) #: Array[String]
      case global_context
      when Hash
        Array(global_context[key] || global_context[key.to_s])
      else
        []
      end
    end
  end
end
