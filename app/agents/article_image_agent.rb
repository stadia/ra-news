# frozen_string_literal: true
# rbs_inline: enabled

class ArticleImageAgent < RubyLLM::Agent
  model "nano-banana-pro-preview"
  # model "gemini-3-pro-image-preview"

  temperature 0.5

  instructions {
    <<~PROMPT
      - 1200x675px, 16:9 비율로 생성한다.
      - 클리셰(악수, 휴머노이드 로봇 등)와 사실적 인체 묘사는 피한다.
      - 이미지 내 텍스트는 가급적 한국어/일본어가 아닌 영어를 사용한다.
    PROMPT
  }
end
