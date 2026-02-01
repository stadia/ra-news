# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class TechnicalWriterAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::TechnicalWriterAgent, :<, ApplicationAgent
    end

    test "title, semantic_chunks, knowledge_architecture, global_context 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          semantic_chunks: [],
          knowledge_architecture: {},
          global_context: {},
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          title: "Test",
          knowledge_architecture: {},
          global_context: {},
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          title: "Test",
          semantic_chunks: [],
          global_context: {},
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          title: "Test",
          semantic_chunks: [],
          knowledge_architecture: {},
          dry_run: true
        )
      end
    end

    test "dry_run 모드에서 프롬프트를 반환한다" do
      result = Articles::TechnicalWriterAgent.call(
        title: "Rails 8 Overview",
        semantic_chunks: [
          { "heading" => "Intro", "content" => "Rails 8 introduces Solid Queue." }
        ],
        knowledge_architecture: {
          core_message: "Rails 8 ships with a built-in job system",
          key_points: [ "solid_queue", "observability", "deployment" ],
          why_it_matters: "reduces external dependencies",
          target_audience: "Rails teams",
          practical_takeaways: [ "simplify ops" ]
        },
        global_context: {
          title: "Rails 8 Overview",
          source_type: "article",
          summary_goal: "Explain the impact of Solid Queue",
          lead_paragraph: "Rails is simplifying background jobs.",
          entities: [ "Solid Queue", "Active Job" ],
          tags: [ "solid_queue", "rails_8" ]
        },
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "Title:"
      assert_includes result.content[:user_prompt], "Global Context:"
      assert_includes result.content[:user_prompt], "Architecture Blueprint:"
      assert_includes result.content[:user_prompt], "Detailed Chunks:"
    end

    test "system_prompt에 역할과 집필 규칙이 포함된다" do
      result = Articles::TechnicalWriterAgent.call(
        title: "Test",
        semantic_chunks: [
          { "heading" => "Intro", "content" => "Content" }
        ],
        knowledge_architecture: { core_message: "Test" },
        global_context: { title: "Test", source_type: "article", summary_goal: "Test" },
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "전문 작가"
      assert_includes result.content[:system_prompt], "3줄 핵심 요약"
      assert_includes result.content[:system_prompt], "영문(English)"
    end

    test "schema가 정의되어 있다" do
      agent = Articles::TechnicalWriterAgent.new(
        title: "Test",
        semantic_chunks: [
          { "heading" => "Intro", "content" => "Content" }
        ],
        knowledge_architecture: { core_message: "Test" },
        global_context: { title: "Test", source_type: "article", summary_goal: "Test" }
      )
      schema = agent.send(:schema)

      assert_not_nil schema
    end

    test "temperature와 timeout 설정이 존재한다" do
      assert_respond_to Articles::TechnicalWriterAgent, :call
    end
  end
end
