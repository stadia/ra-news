# frozen_string_literal: true
# rbs_inline: enabled

require "ruby_llm/schema"

class GroundingSchema < RubyLLM::Schema
  boolean :grounded, description: "요약 전체가 원문에 근거하면 true (참고용 종합 판정)"

  number :score, minimum: 0, maximum: 1,
    description: "근거 있는 주장 비율 0.0~1.0. 원문에 명시된 사실로 뒷받침되는 주장 / 전체 주장."

  array :unsupported_claims, description: "원문에 근거가 없는(환각) 주장 목록" do
    object do
      string :claim, description: "원문에 근거 없는 주장 문장"
      string :field, description: "주장이 나온 필드: summary_key / summary_introduction / summary_body / summary_conclusion"
      string :reason, description: "왜 근거 없다고 판단했는지 간단히"
    end
  end
end
