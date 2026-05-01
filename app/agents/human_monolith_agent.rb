# frozen_string_literal: true
# rbs_inline: enabled

class HumanMonolithAgent < RubyLLM::Agent
  model "glm-5.1", provider: :openrouter, assume_model_exists: true
  temperature 0.3
  skills "app/skills", only: [ :humanize_korean ]

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

    object :category_detection, description: "카테고리 탐지 (before → after)" do
      array :items, description: "카테고리 탐지 표 항목" do
        string :id, description: "패턴 ID (예: D-4)"
        string :pattern, description: "패턴명"
        integer :before, description: "원문 탐지 수"
        integer :after, description: "윤문 후 탐지 수"
      end
    end

    array :highlights, description: "주요 변경 하이라이트 (3~5건)" do
      string :category, description: "카테고리 ID"
      string :before, description: "변경 전 (100자 이내)"
      string :after, description: "변경 후 (100자 이내)"
    end

    array :self_check_items, description: "자체검증 6항 상세 결과" do
      string :label, description: "검증 항목명"
      boolean :passed, description: "통과 여부"
    end

    array :residual_findings, description: "잔존 finding (있으면)" do
      string :id, description: "패턴 ID"
      string :severity, description: "심각도"
      string :reason, description: "잔존 사유"
    end

    string :grade_reason, description: "등급 판정 사유"
    string :status_message, description: "한 줄 상태 메시지"
    boolean :over_polish_aborted, description: "과윤문으로 인한 중단 여부"
  end

  instructions {
    <<~PROMPT
#{File.read(File.join(__dir__, "humanize-monolith.md"))}
    PROMPT
  }
end
