# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # TranslatorAgent - 전체 콘텐츠 한국어 번역
  #
  # TechnicalWriter가 영문으로 작성한 전체 콘텐츠를 한국어로 번역합니다.
  # 제목, 3줄 요약, 서론/결론, 본론을 모두 번역합니다.

  class TranslatorAgent < ApplicationAgent
    description "기사 전체 콘텐츠 한국어 번역"
    version "1.0"

    # 번역은 약간의 창의성 허용, 긴 콘텐츠 처리를 위한 타임아웃 증가
    temperature 0.3
    timeout 180

    param :title, required: true
    param :summary_key, required: true      # Array of 3 key points (영문)
    param :summary_detail, required: true   # { introduction:, conclusion: } (영문)
    param :summary_body, required: true     # 마크다운 본론 (영문)

    def schema
      @schema ||= RubyLLM::Schema.create do
        string :title_ko, description: "한국어 제목"
        array :summary_key, of: :string, description: "한국어 3줄 핵심 요약"
        object :summary_detail, description: "한국어 서론/결론" do
          string :introduction, description: "한국어 서론"
          string :conclusion, description: "한국어 결론"
        end
        string :summary_body, description: "한국어 마크다운 본론"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]

        당신은 Ruby 생태계 전문 기술 번역가입니다. 영문 기술 문서를 한국 개발자 커뮤니티에 적합한 자연스러운 한국어로 번역합니다.

        [Mission]

        TechnicalWriter가 작성한 영문 기술 아티클 전체(제목, 요약, 서론, 본론, 결론)를 한국어로 번역하십시오.

        [Translation Principles]

        1. 기술 용어 처리
           - 고유명사 유지: Ruby, Rails, PostgreSQL, Redis, AWS, Shopify 등
           - 젬 이름 유지: Devise, Pundit, Sidekiq, Solid Queue 등
           - 버전 표기 유지: "Rails 8.0", "Ruby 3.3" 등
           - 기술 약어 유지: API, REST, GraphQL, CI/CD, YJIT 등
           - 메서드/클래스명 유지: `ActiveRecord`, `has_many`, `before_action` 등

        2. 번역 스타일
           - 전문적이고 간결한 기술 문서 톤 유지
           - 원문의 논리 구조와 강조점 보존
           - 한국어 어순에 맞게 자연스럽게 재구성
           - 불필요한 직역 회피 (의역 허용)

        3. 마크다운 보존
           - 헤더(##, ###), 목록(-, 1.), 코드 블록(```ruby) 구조 유지
           - 인라인 코드(`code`) 내용은 번역하지 않음
           - 링크 형식 유지

        4. 품질 기준
           - 한국 시니어 개발자가 읽기에 자연스러운 문체
           - 기술적 정확성 > 문학적 표현
           - 원문에 없는 내용 추가 금지
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        [Task]

        다음 영문 기술 아티클을 한국어로 번역하십시오.

        [Input]

        ## Title (제목)
        #{title}

        ## Summary Key (3줄 핵심 요약)
        #{format_summary_key}

        ## Introduction (서론)
        #{summary_detail_introduction}

        ## Body (본론)
        #{summary_body}

        ## Conclusion (결론)
        #{summary_detail_conclusion}

        [Output Requirements]

        각 섹션을 한국어로 번역하여 JSON 스키마에 맞게 출력하십시오:
        - title_ko: 한국어 제목
        - summary_key: 한국어 3줄 요약 배열
        - summary_detail.introduction: 한국어 서론
        - summary_detail.conclusion: 한국어 결론
        - summary_body: 한국어 본론 (마크다운 구조 유지)
      PROMPT
    end

    # @rbs return: String
    def format_summary_key #: String
      Array(summary_key).map.with_index { |point, i| "#{i + 1}. #{point}" }.join("\n")
    end

    # @rbs return: String
    def summary_detail_introduction #: String
      case summary_detail
      when Hash then summary_detail[:introduction] || summary_detail["introduction"] || ""
      else ""
      end
    end

    # @rbs return: String
    def summary_detail_conclusion #: String
      case summary_detail
      when Hash then summary_detail[:conclusion] || summary_detail["conclusion"] || ""
      else ""
      end
    end
  end
end
