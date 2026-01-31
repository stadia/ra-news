# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # ContextProviderAgent - 배경 정보 및 관련 토픽 제공
  #
  # 기사에 대한 추가적인 맥락 정보를 제공합니다.
  # 관련 기술, 젬, 커뮤니티 인사이트를 포함합니다.
  #
  # @example
  #   result = Articles::ContextProviderAgent.call(
  #     content: "Solid Queue 소개...",
  #     title: "Understanding Solid Queue",
  #     detected_keywords: ["solid_queue", "active_job"]
  #   )
  #   result.content[:related_gems] # ["sidekiq", "good_job", "delayed_job"]
  #
  class ContextProviderAgent < ApplicationAgent
    description "기사 배경 정보 및 관련 토픽 제공"
    version "1.0"

    # 창의적인 연결과 배경 정보 제공을 위해 높은 temperature
    temperature 0.6

    param :content, required: true
    param :title, required: true
    param :detected_keywords, default: []

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :background_context, description: "기술적 배경 설명 (200-400자)"

        array :related_topics, of: :string, description: "관련 토픽/기술 (최대 5개)"

        array :related_gems, of: :string, description: "관련 Ruby 젬 (최대 5개)"

        string :community_insight, description: "Ruby 커뮤니티 관점에서의 의미 (100-200자)"

        object :prerequisites, description: "선행 지식" do
          array :concepts, of: :string, description: "알아야 할 개념"
          string :difficulty_level, description: "난이도 (beginner, intermediate, advanced)"
        end
      end
    end

    private

    def system_prompt
      <<~PROMPT
        ## 역할
        당신은 Ruby 생태계에 정통한 기술 컨설턴트입니다.
        기사의 맥락을 파악하고 독자가 더 깊이 이해할 수 있도록 배경 정보를 제공합니다.

        ## 배경 설명 (background_context) 작성

        ### 포함해야 할 내용
        - 이 기술/기능이 등장한 이유
        - 해결하려는 문제
        - 기존 방식과의 차이점
        - 관련 역사적 맥락 (해당되는 경우)

        ### 작성 스타일
        - 200-400자
        - 객관적이고 정보적인 톤
        - 기술적 정확성 유지
        - Ruby 초심자도 이해할 수 있게

        ## 관련 토픽 (related_topics)
        - 최대 5개
        - 직접적으로 관련된 기술, 개념, 패턴
        - Ruby 생태계 내에서의 연결고리 강조
        - 예: Active Record → "ORM", "데이터베이스 마이그레이션", "쿼리 최적화"

        ## 관련 젬 (related_gems)
        - 최대 5개
        - 실제 존재하는 젬만 추천
        - 비슷한 문제를 해결하는 대안 또는 보완 젬
        - 인기 있고 활발히 유지보수되는 젬 우선

        ## 커뮤니티 인사이트 (community_insight)
        - 100-200자
        - Ruby 커뮤니티에서 이 주제가 갖는 의미
        - 트렌드, 논의, 반응 등
        - 실무자 관점에서의 중요성

        ## 선행 지식 (prerequisites)

        ### 개념 (concepts)
        - 이 글을 이해하기 위해 알아야 할 개념
        - 최대 5개
        - 구체적이고 검색 가능한 용어

        ### 난이도 (difficulty_level)
        - beginner: Ruby 기초 지식만 필요
        - intermediate: Rails 경험 또는 특정 도메인 지식 필요
        - advanced: 깊은 내부 동작 이해 또는 전문 지식 필요
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 기사에 대한 배경 정보와 관련 토픽을 제공해주세요.

        ## 제목
        #{title}

        #{keywords_section}

        ## 본문
        #{truncated_content}
      PROMPT
    end

    # @rbs return: String
    def keywords_section #: String
      return "" if detected_keywords.blank?

      <<~SECTION
        ## 감지된 키워드
        #{detected_keywords.join(", ")}
      SECTION
    end

    # @rbs return: String
    def truncated_content #: String
      content.to_s.truncate(6000, omission: "\n\n[... 이하 생략 ...]")
    end
  end
end
