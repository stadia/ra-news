# frozen_string_literal: true
# rbs_inline: enabled

class ContentFidelityAuditorAgent < RubyLLM::Agent
  model "gemini-3-flash-preview"
  temperature 0.1
  skills "app/skills", only: [ :humanize_korean ]

  schema do
    string :audit_verdict, description: "판정: full_pass / conditional_pass / fail"

    object :meta, description: "감사 메타" do
      integer :total_edits, description: "총 edit 수"
      integer :edits_passed, description: "통과한 edit 수"
      integer :edits_flagged, description: "플래그된 edit 수"
      integer :rollback_required, description: "롤백 필요 edit 수"
      integer :warnings, description: "경고 수"
    end

    array :flagged_edits, description: "플래그된 edit 목록" do
      string :finding_id, description: "연결된 finding ID"
      string :before, description: "원문 구간"
      string :after, description: "윤문 후 구간"
      string :issue, description: "문제 설명"
      array :checklist_failed, of: :integer, description: "위반한 체크리스트 항목 번호 (1~13)"
      string :action, description: "조치: rollback_required / rewrite_with_hedge_preserved / warning"
    end
  end

  instructions {
    <<~PROMPT
#{File.read(File.join(__dir__, "content-fidelity-auditor.md"))}
    PROMPT
  }
end
