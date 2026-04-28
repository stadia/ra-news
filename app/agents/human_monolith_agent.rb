# frozen_string_literal: true
# rbs_inline: enabled

class HumanMonolithAgent < RubyLLM::Agent
  model "gemini-3-flash-preview"
  temperature 0.3
  skills "app/skills", only: [:humanize_korean]

  schema do
    string :rewritten_text, description: "윤문된 텍스트 전체"

    object :metrics, description: "윤문 메트릭" do
      integer :original_chars, description: "원본 글자수"
      integer :rewritten_chars, description: "윤문 글자수"
      number :change_rate, description: "변경률 (0.0~1.0)"
      integer :self_check_passed, description: "자체검증 통과 항목 수 (최대 6)"
      string :grade, description: "등급: A/B/C/D"
      string :estimated_genre, description: "추정 장르"
    end

    object :category_detection, description: "카테고리별 탐지 (before → after)" do
      array :items, description: "탐지 항목 목록" do
        string :id, description: "패턴 ID (예: D-4)"
        string :pattern_label, description: "패턴 레이블"
        integer :before_count, description: "원문에서 탐지 수"
        integer :after_count, description: "윤문 후 탐지 수"
      end
    end

    array :highlights, description: "주요 변경 하이라이트 (3~5건)" do
      string :category, description: "카테고리 ID"
      string :before, description: "변경 전 (100자 이내)"
      string :after, description: "변경 후 (100자 이내)"
    end

    array :residual_findings, description: "잔존 finding (있으면)" do
      string :id, description: "패턴 ID"
      string :severity, description: "심각도"
      string :reason, description: "잔존 사유"
    end

    boolean :over_polish_aborted, description: "과윤문으로 인한 중단 여부"
  end

  instructions {
    <<~PROMPT
      CRITICAL: 응답은 스키마에 정의된 필드만 채운다. 설명문, 메타 코멘트, 사족을 출력하지 않는다.
      CRITICAL: 원문의 의미·사실·주장·수치·고유명사·인용은 한 글자도 변경하지 않는다.
      CRITICAL: 탐지되지 않은 구간은 건드리지 않는다.

      #{File.read(File.join(__dir__, "humanize-monolith.md"))}
    PROMPT
  }
end