# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # ContextProviderAgent - 배경 정보 및 관련 토픽 제공
  #
  # 기사에 대한 추가적인 맥락 정보를 제공합니다.
  # 관련 기술, 젬, 커뮤니티 인사이트를 포함합니다.

  class ContextProviderAgent < ApplicationAgent
    description "기사 배경 정보 및 관련 토픽 제공"

    # 창의적인 연결과 배경 정보 제공을 위해 높은 temperature
    temperature 0.6

    param :knowledge_architecture, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        object :contextual_insights do
          object :market_landscape do
            array :competitors, of: :string, description: "기술의 경쟁자"
            string :comparative_advantage, description: "루비 생태계의 비교적 우위"
          end
          object :industry_adoption, description: "기업의 루비 사용" do
            array :use_cases, of: :string, description: "루비 사용 사례"
            string :business_value, description: "루비 사용의 기업 가치"
          end
          object :community_pulse, description: "커뮤니티의 흐름" do
            string :github_activity_level, description: "GitHub 활동 수준"
            string :expert_opinions, description: "전문가의 의견"
          end
          object :learning_path, description: "학습 경로" do
            array :prerequisites, of: :string, description: "이 기술을 배우기 위한 전제 조건"
            array :recommended_resources, of: :string, description: "추천 리소스"
          end
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]

        당신은 전 세계 기술 동향을 꿰뚫고 있는 전략 컨설턴트입니다. 단순히 기술이 '무엇(What)'인지 아는 것에 그치지 않고, 왜(Why) 지금 이 기술이 부상하는지, 다른 생태계(Go, Rust, Node.js 등)와 비교했을 때 루비만의 강점은 무엇인지를 분석합니다. 당신의 목표는 독자가 이 기술을 도입할지 말지 결정할 수 있는 **'의사결정 데이터'**를 제공하는 것입니다.

        [Instructions]

        1. 당신은 '기술 콘텐츠 지능화 팀'의 인사이트 리서처입니다.
        2. 정보의 확장: 원문에 포함된 내용만 요약하지 마십시오. 원문 밖의 데이터(타 언어 비교, 시장 동향, 실무 적용 사례)를 가져와 지식의 깊이를 더하십시오.
        3. 루비 생태계 중심: 모든 인사이트는 "루비 개발자와 기업에게 어떤 전략적 이득을 주는가?"에 초점을 맞추어야 합니다.
        4. 영문 작성 유지: 기술적 일관성을 위해 모든 인사이트는 **영문(English)**으로 작성하십시오.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task] Knowledge Architect가 설계한 기술 구조도를 바탕으로, 원문에는 없는 외부 전략 인사이트를 리서치하여 보강하십시오.

        [Input]#{' '}
        #{format_knowledge_architecture}

        [Research Guidelines]

        1. Comparative Analysis (경쟁 및 대체 기술):

          * 원문의 기술과 경쟁 관계에 있는 타 언어/프레임워크의 도구를 식별하십시오. (예: Ruby의 Prism vs Python의 정적 분석 도구)
          * 루비 생태계 내에서의 대안(Alternatives)도 함께 제시하십시오.

        2. Market & Career Impact (시장 및 커리어 영향):

          * 이 기술이 실제 채용 시장이나 대규모 서비스 운영 환경에서 어떤 가치를 지니는지 분석하십시오.
          * 개발자의 생산성 향상 수치나 비용 절감 효과가 있다면 언급하십시오.

        3. Historical & Future Context (과거와 미래):

          * 이 기술이 나오게 된 역사적 배경(기존 도구의 한계)과 앞으로의 로드맵(Ruby 4.x 등)을 연결하십시오.

        4. Community Signals (커뮤니티 시그널):

          * GitHub Discussions, Reddit, Ruby Weekly 등에서 이 기술에 대해 가장 많이 언급되는 우려 사항이나 기대치를 리서치하여 정리하십시오.
      PROMPT
    end

    # @rbs return: String
    def format_knowledge_architecture #: String
      format_as_markdown(knowledge_architecture)
    end
  end
end
