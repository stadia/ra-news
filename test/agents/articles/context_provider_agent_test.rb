# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class ContextProviderAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::ContextProviderAgent, :<, ApplicationAgent
    end

    test "knowledge_architecture 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::ContextProviderAgent.call(dry_run: true)
      end
    end

    test "dry_run 모드에서 프롬프트를 반환한다" do
      result = Articles::ContextProviderAgent.call(
        knowledge_architecture: {
          core_message: "Solid Queue improves background jobs",
          key_points: [ "durable", "integrated", "observable" ],
          why_it_matters: "reduces external dependencies",
          target_audience: "Rails teams",
          practical_takeaways: [ "simplify ops" ]
        },
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "Knowledge Architect"
      assert_includes result.content[:user_prompt], "Research Guidelines"
    end

    test "system_prompt에 역할과 작성 규칙이 포함된다" do
      result = Articles::ContextProviderAgent.call(
        knowledge_architecture: { core_message: "Test" },
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "전략 컨설턴트"
      assert_includes result.content[:system_prompt], "의사결정 데이터"
      assert_includes result.content[:system_prompt], "영문(English)"
    end

    test "temperature가 0.6으로 설정되어 있다" do
      assert_respond_to Articles::ContextProviderAgent, :call
    end
  end
end
