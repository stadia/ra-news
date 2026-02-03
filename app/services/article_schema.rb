# frozen_string_literal: true

# rbs_inline: enabled

require "ruby_llm/schema"

class ArticleSchema < RubyLLM::Schema
  string :title_ko, description: "한국어 제목"

  array :summary_key, of: :string, description: "핵심 요약 3개"

  object :summary_detail, description: "상세 요약" do
    string :introduction, description: "서론(introduction)"
    string :conclusion, description: "결론(conclusion)"
  end

  string :summary_body, description: "마크다운 본론 (body)"

  array :tags, of: :string, description: "주요 태그(tags) 최대 3개"

  boolean :is_related, description: "Ruby Programming Language와의 관련 여부"
end
