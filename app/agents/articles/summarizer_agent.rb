# frozen_string_literal: true

# rbs_inline: enabled

module Articles
  # SummarizerAgent - 핵심 요약 3줄 + 서론/결론
  #
  # 기사의 핵심 내용을 3가지 포인트로 요약하고,
  # 서론(배경)과 결론(시사점)을 작성합니다.

  class SummarizerAgent < ApplicationAgent
    description "기사 핵심 요약 및 서론/결론 생성"
    version "1.0"

    # 더 강력한 모델 사용, 창의적 요약 허용
    model "gemini-2.5-flash"
    temperature 0.5
    timeout 90

    param :cleaned_content, required: true
    param :semantic_chunks, required: true

    def schema
      @schema ||= RubyLLM::Schema.create do
        array :key_findings, of: :string, description: "핵심 포인트"
        string :content_type, description: "콘텐츠 유형 (tutorial, news, opinion, reference)"
      end
    end

    private

    def system_prompt
      <<~PROMPT
        [Persona]#{' '}

        Ruby 커뮤니티의 오피니언 리더이자 전략적 아키텍트#{' '}

        [Mission]#{' '}

        뉴스, 블로그, 기술 아티클 등 다양한 소스에서 Ruby 생태계에 영향을 미치는 핵심 인사이트와 트렌드를 추출하라.
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        다음 기사를 요약해주세요.

        ## 정규화된 텍스트
        #{cleaned_content}

        ## 논리적 청킹
        #{semantic_chunks}
      PROMPT
    end
  end
end
