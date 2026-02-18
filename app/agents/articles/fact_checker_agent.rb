# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # FactCheckerAgent - Ruby 관련성 판단
  #
  # 콘텐츠가 Ruby 프로그래밍 언어와 관련이 있는지 판단합니다.
  # 단순 키워드 매칭이 아닌 맥락 기반 분석을 수행합니다.
  #
  # @example
  #   result = Articles::FactCheckerAgent.call(
  #     content: "Rails 8의 새로운 기능...",
  #     title: "Rails 8 Released",
  #     url: "https://example.com/rails-8"
  #   )
  #   result.content[:is_related] # true
  #
  class FactCheckerAgent < ApplicationAgent
    description "콘텐츠의 Ruby 관련성 판단"

    # 기본 모델 설정 상속 (gemini-2.5-flash, temp 0.5)
    cache for: 12.hours

    param :content, required: true
    param :title, required: true
    param :url, default: nil

    def schema
      @schema ||= RubyLLM::Schema.create do
        boolean :is_related, description: "Ruby/Rails 관련 여부"
        string :relevance_reason, description: "판단 근거 (1-2문장)"
        array :detected_keywords, of: :string, description: "발견된 Ruby 관련 키워드"
        integer :confidence_score, description: "확신도 (0-100)"
        string :primary_topic, description: "주요 주제 분류"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        ## 역할
        당신은 Ruby 생태계 콘텐츠 큐레이터입니다. 주어진 콘텐츠가 Ruby 커뮤니티에 가치 있는지 판단합니다.

        ## 관련성 판단 기준

        ### TRUE (관련 있음)
        - Ruby 언어 자체 (문법, 기능, 버전, 성능)
        - Ruby on Rails 및 관련 프레임워크 (Sinatra, Hanami 등)
        - Ruby 젬 (gems) 및 라이브러리
        - Ruby 개발 도구 (RubyMine, Sorbet, RBS, Steep 등)
        - Ruby 커뮤니티 소식 (RubyConf, RubyKaigi, 유명 Rubyist)
        - Ruby 기업/조직 (Shopify Ruby 팀, 37signals 등)
        - Ruby 성능, 보안, 베스트 프랙티스
        - JRuby, TruffleRuby 등 대체 구현체

        ### FALSE (관련 없음)
        - 다른 프로그래밍 언어만 다루는 콘텐츠
        - Ruby 언급 없이 일반적인 웹 개발 내용
        - Ruby가 부수적으로만 언급되고 핵심이 아닌 경우
        - 프로그래밍과 무관한 콘텐츠

        ### 경계 사례 판단
        - DevOps/인프라 도구 (Ruby로 작성되었거나 Ruby와 통합되면 TRUE)
        - 데이터베이스 (ActiveRecord 맥락이면 TRUE)
        - 프론트엔드 (Hotwire, Stimulus 맥락이면 TRUE)
        - 범용 프로그래밍 개념 (Ruby 예제가 중심이면 TRUE)

        ## 확신도 기준
        - 90-100: 명확한 Ruby 핵심 콘텐츠
        - 70-89: Ruby 관련이 확실하나 부분적
        - 50-69: 간접적 관련성
        - 0-49: 관련성 낮음

        ## 주요 주제 분류
        - language_core: Ruby 언어 자체
        - framework: Rails, Sinatra 등 프레임워크
        - gem: 젬/라이브러리
        - tooling: 개발 도구
        - community: 커뮤니티/이벤트
        - tutorial: 튜토리얼/가이드
        - news: 뉴스/발표
        - other: 기타
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 콘텐츠의 Ruby 관련성을 분석해주세요.

        ## 제목
        #{title}

        #{url_section}

        ## 본문
        #{truncated_content}
      PROMPT
    end

    # @rbs return: String
    def url_section #: String
      return "" if url.blank?

      <<~SECTION
        ## URL
        #{url}
      SECTION
    end

    # @rbs return: String
    def truncated_content #: String
      # 분석에 필요한 적절한 길이로 제한
      content.to_s.truncate(8000, omission: "\n\n[... 이하 생략 ...]")
    end
  end
end
