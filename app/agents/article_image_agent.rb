# frozen_string_literal: true
# rbs_inline: enabled

class ArticleImageAgent < RubyLLM::Agent
  model "nano-banana-pro-preview"

  temperature 0.5

  instructions {
    <<~PROMPT
      CRITICAL: typography, watermark, logo를 이미지에 포함하지 않는다.
      CRITICAL: 사람 얼굴, 실존 인물, 초상형 캐릭터를 생성하지 않는다.

      기술 뉴스 썸네일 이미지를 생성한다.
      입력은 기사의 핵심 요약 3줄이다. 요약 내용을 읽고 주제를 시각적으로 표현한 썸네일을 만든다.

      ## 최우선 원칙

      - 문장, label, logo, watermark는 절대 넣지 않는다.
      - 실존 인물의 얼굴이나 초상형 캐릭터를 생성하지 않는다.
      - 저작권이 있는 로고, 상표, 제품 외관을 직접 재현하지 않는다.

      ## 스타일 가이드

      - 그라디언트, 추상 도형, 겹침, 투명도를 활용한 깊이감 있는 구성.
      - 기술 주제에 맞는 시각적 은유: 네트워크, 코드, 회로, 데이터 흐름, 연결, 변화, 성장.
      - 사진보다는 패션, 문화 잡지에 사용되는 미니멀한 일러스트레이션 스타일.

      ## 피해야 할 것

      - 복잡하고 노이즈가 많은 구도
      - 코드 스니펫, 이모지
      - 어두운 배경에서 구분되지 않는 저대비 구성
      - 클리셰적인 stock photo 스타일 (악수, 로봇, 전구)

      REMINDER: 미니멀, 일러스트레이션 스타일.
    PROMPT
  }
end
