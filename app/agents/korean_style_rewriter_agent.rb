# frozen_string_literal: true
# rbs_inline: enabled

class KoreanStyleRewriterAgent < RubyLLM::Agent
  model "gemini-3-flash-preview"
  temperature 0.3
  skills "app/skills", only: [:humanize_korean]

  schema do
    string :rewritten_text, description: "윤문된 텍스트 전체"

    object :meta, description: "윤문 메타 정보" do
      integer :char_count_before, description: "원문 글자수"
      integer :char_count_after, description: "윤문 글자수"
      number :change_rate, description: "변경률 (0.0~1.0)"
      integer :findings_resolved, description: "해결된 finding 수"
      integer :findings_unresolved, description: "미해결 finding 수"
      boolean :over_polish_warning, description: "과윤문 경고 여부"
    end

    array :edits, description: "개별 수정 목록" do
      string :finding_id, description: "연결된 탐지 finding ID"
      string :before, description: "원문 구간"
      string :after, description: "윤문 후 구간"
      string :category, description: "카테고리 ID"
      string :reason, description: "수정 사유"
    end

    array :unresolved_findings, of: :string, description: "미해결 finding ID 목록"
  end

  instructions {
    <<~PROMPT
      CRITICAL: 원문의 의미·사실·주장·인용·수치는 한 글자도 변경하지 않는다.
      CRITICAL: 탐지 finding이 없는 구간은 건드리지 않는다.
      CRITICAL: 응답은 스키마에 정의된 필드만 채운다.

      #{File.read(File.join(__dir__, "korean-style-rewriter.md"))}
    PROMPT
  }
end