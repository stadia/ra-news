# frozen_string_literal: true
# rbs_inline: enabled

class HumanMonolithAgent < RubyLLM::Agent
  model "deepseek-v4-flash", provider: :openrouter, assume_model_exists: true
  # model "gemini-3-flash-preview"
  temperature 0.3
  # skills "app/skills", only: [ "humanize-korean" ]

  schema do
    array :summary_key, of: :string, description: "윤문된 핵심 요약 배열 (원본 길이·항목 수 유지)"

    object :summary_detail, description: "윤문된 상세 요약" do
      string :introduction, description: "윤문된 introduction (200-300자)"
      string :conclusion, description: "윤문된 conclusion (200-300자)"
    end

    string :summary_body, description: "윤문된 마크다운 본론 (헤딩·구조·링크 보존)"

    object :metrics, description: "윤문 메트릭" do
      integer :original_chars, description: "원본 총 글자수 (key+detail+body)"
      integer :rewritten_chars, description: "윤문 총 글자수"
      number :change_rate, description: "변경률 (0.0~1.0)"
      string :grade, description: "등급: A/B/C/D"
    end

    boolean :over_polish_aborted, description: "변경률 50% 초과로 롤백되었는지 여부"
  end

  QUICK_RULES_PATH = Rails.root.join("app/skills/humanize-korean/references/quick-rules.md").freeze

  instructions {
    <<~PROMPT
      #{File.read(File.join(__dir__, "humanize-monolith.md"))}

      ---

      # Quick Rules (slim rulebook — S1·S2 핵심 패턴)

      #{File.read(QUICK_RULES_PATH)}
    PROMPT
  }
end
