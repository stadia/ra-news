# frozen_string_literal: true
# rbs_inline: enabled

class AiTellDetectorAgent < RubyLLM::Agent
  model "gemini-3-flash-preview"
  temperature 0.2
  skills "app/skills", only: [:humanize_korean]

  schema do
    object :meta, description: "탐지 메타 정보" do
      integer :input_length, description: "입력 텍스트 글자수"
      string :estimated_genre, description: "추정 장르: 칼럼|리포트|블로그|공적"
      integer :sentence_count, description: "문장 수"
      object :sentence_length_stats, description: "문장 길이 통계" do
        number :mean, description: "평균 문장 길이"
        number :stdev, description: "표준편차"
        boolean :uniformity_warning, description: "균일성 경고 (stdev < 8)"
      end
      integer :detected_count, description: "탐지된 총 finding 수"
      number :ai_tell_density, description: "AI 티 밀도 (0.0~1.0)"
      number :severity_weighted_score, description: "심각도 가중 점수 (0~100)"
    end

    array :findings, description: "탐지된 AI 티 패턴 목록" do
      string :id, description: "Finding 고유 ID"
      string :category, description: "카테고리 ID"
      string :category_label, description: "카테고리 레이블"
      string :severity, description: "심각도: S1/S2/S3"
      string :scope, description: "범위: span 또는 document"
      string :text_span, description: "탐지된 원문 구간"
      integer :start, description: "시작 offset"
      integer :end, description: "종료 offset"
      string :reason, description: "탐지 사유"
      string :suggested_fix, description: "권장 수정안"
    end
  end

  instructions {
    <<~PROMPT
      CRITICAL: 응답은 스키마에 정의된 필드만 채운다. 설명문, 메타 코멘트, 사족을 출력하지 않는다.

      #{File.read(File.join(__dir__, "ai-tell-detector.md"))}
    PROMPT
  }
end