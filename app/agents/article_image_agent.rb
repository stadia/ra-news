# frozen_string_literal: true
# rbs_inline: enabled

class ArticleImageAgent < RubyLLM::Agent
  model "nano-banana-pro-preview"
  # model "gemini-3-pro-image-preview"

  temperature 0.5

  instructions {
    <<~PROMPT
      - 1200x675px, 16:9 비율로 생성한다.
      - 클리셰(악수, 휴머노이드 로봇, 회로 기판/PCB 트레이스 패턴 배경 등)와 사실적 인체 묘사는 피한다. 특히 회로 기판 모티브는 기술 기사 섬네일에서 과사용되므로 배경/장식 요소로 쓰지 않는다.
      - 이미지 내 텍스트는 가급적 한국어/일본어가 아닌 영어를 사용한다.
      - 색상은 60:30:10 법칙을 따른다: 프레임의 60%는 지배 색상, 30%는 보조 색상, 10%는 시선을 끄는 포인트(accent) 색상으로 구성하여 시각적 조화를 만든다.
    PROMPT
  }
end
