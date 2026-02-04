# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class KnowledgeAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::KnowledgeAgent, :<, ApplicationAgent
    end

    test "cleaned_content와 semantic_chunks 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::KnowledgeAgent.call(semantic_chunks: [], dry_run: true)
      end

      assert_raises(ArgumentError) do
        Articles::KnowledgeAgent.call(cleaned_content: "Content", dry_run: true)
      end
    end

    test "dry_run 모드에서 프롬프트를 반환한다" do
      result = Articles::KnowledgeAgent.call(
        cleaned_content: "Ruby 3.4 introduces pattern matching improvements.",
        semantic_chunks: [
          { "heading" => "Overview", "content" => "Pattern matching is expanded." }
        ],
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "Knowledge Architecture"
      assert_includes result.content[:user_prompt], "### Overview"
    end

    test "system_prompt에 역할과 태그 규칙이 포함된다" do
      result = Articles::KnowledgeAgent.call(
        cleaned_content: "Test",
        semantic_chunks: [
          { "heading" => "Intro", "content" => "Intro content" }
        ],
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "기술 콘텐츠 분석가"
      assert_includes result.content[:system_prompt], "Tag Extraction Rules"
      assert_includes result.content[:system_prompt], "snake_case"
    end

    test "schema가 정의되어 있다" do
      agent = Articles::KnowledgeAgent.new(
        cleaned_content: "Test",
        semantic_chunks: [
          { "heading" => "Intro", "content" => "Intro content" }
        ]
      )
      schema = agent.send(:schema)

      assert_not_nil schema
    end
  end
end
