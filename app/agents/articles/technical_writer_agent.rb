# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  class TechnicalWriterAgent < ApplicationAgent
    description "지식 설계도 기반 기술 아티클 작성"
    version "1.0"
    model "gemini-3-flash-preview"

    temperature 0.6
    timeout 120

    param :title, required: true
    param :semantic_chunks, required: true
    param :knowledge_architecture, required: true
    param :global_context, required: true

    def schema
      @schema ||= ArticleSchema.new
    end

    private

    def system_prompt
      <<~PROMPT
        기술 콘텐츠 전문 작가

        [Goal]
        독자가 가치를 느끼고, 끝까지 읽었을 때 기술적 의사결정을 내릴 수 있는 아티클 작성

        [Rules]
        - 구조적 집필: 서론-본론-결론 구조
        - 지식의 합성: Knowledge Architect의 기술적 깊이를 자연스럽게 융합
        - 전문적 톤: 시니어 루비 개발자에게 적합한 건조하고 통찰력 있는 문체
        - 본문은 마크다운 구조로 작성해야 합니다.
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
          * 각 요약은 80자 이상의 하나의 완성된 문장으로 작성하십시오.

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
