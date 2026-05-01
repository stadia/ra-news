# frozen_string_literal: true
# rbs_inline: enabled

class NaturalnessReviewerAgent < RubyLLM::Agent
  model "glm-5.1", provider: :openrouter, assume_model_exists: true
  temperature 0.2
  skills "app/skills", only: [ :humanize_korean ]

  schema do
    object :meta, description: "검증 메타" do
      number :score_before, description: "원본 severity_weighted_score"
      number :score_after, description: "윤문본 severity_weighted_score"
      number :score_improvement, description: "점수 개선폭"
      integer :s1_residual, description: "잔존 S1 건수"
      integer :s2_residual, description: "잔존 S2 건수"
      array :over_polish_signals, of: :string, description: "과윤문 시그널 목록"
      string :verdict, description: "판정: accept / accept_with_note / rewrite_round_2 / rollback_and_rewrite / hold_and_report"
      string :quality_level, description: "품질 등급: A/B/C/D"
    end

    array :residual_findings, description: "잔존 finding 목록" do
      string :category, description: "카테고리 ID"
      string :severity, description: "심각도: S1/S2/S3"
      string :text_span, description: "잔존 텍스트 구간"
      string :reason, description: "잔존 사유"
      string :action, description: "조치: none / rewrite / rollback"
    end

    array :over_polish_findings, description: "과윤문 상세 목록" do
      string :signal, description: "과윤문 시그널"
      string :reason, description: "판정 사유"
    end

    array :unclassified_candidates, description: "미분류 패턴 후보" do
      string :text_span, description: "후보 텍스트 구간"
      integer :frequency, description: "반복 횟수"
      string :reason, description: "후보 사유"
      string :escalation, description: "에스컬레이션 대상"
    end

    object :next_action, description: "다음 단계" do
      string :type, description: "accept / rewrite_round_2 / rollback_and_rewrite / hold_and_report"
      array :targets, of: :string, description: "대상 finding ID 목록"
    end
  end

  instructions {
    <<~PROMPT
#{File.read(File.join(__dir__, "naturalness-reviewer.md"))}
    PROMPT
  }
end
