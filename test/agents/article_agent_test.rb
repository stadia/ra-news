# typed: true
# frozen_string_literal: true

require "test_helper"

class ArticleAgentTest < ActiveSupport::TestCase
  test "summary_body related article links must use Korean title as markdown text" do
    instructions = Rails.root.join("app/agents/article_agent.rb").read

    assert_includes instructions, "[title_ko](path)"
    assert_includes instructions, "주소만 문장에 노출하지 않는다"
  end
end
