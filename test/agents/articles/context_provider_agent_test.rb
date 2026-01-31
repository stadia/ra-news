# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class ContextProviderAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::ContextProviderAgent, :<, ApplicationAgent
    end

    test "content와 title 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::ContextProviderAgent.call(title: "Test")
      end

      assert_raises(ArgumentError) do
        Articles::ContextProviderAgent.call(content: "Test content")
      end
    end

    test "detected_keywords는 선택적이고 기본값은 빈 배열이다" do
      result = Articles::ContextProviderAgent.call(
        content: "Solid Queue introduction",
        title: "Understanding Solid Queue",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      refute_includes result.content[:user_prompt], "감지된 키워드"
    end

    test "detected_keywords가 제공되면 프롬프트에 포함된다" do
      result = Articles::ContextProviderAgent.call(
        content: "Solid Queue introduction",
        title: "Understanding Solid Queue",
        detected_keywords: %w[solid_queue active_job],
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "감지된 키워드"
      assert_includes result.content[:user_prompt], "solid_queue"
      assert_includes result.content[:user_prompt], "active_job"
    end

    test "긴 콘텐츠는 6000자로 제한된다" do
      long_content = "Ruby " * 1500  # 7500자
      result = Articles::ContextProviderAgent.call(
        content: long_content,
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "이하 생략"
    end

    test "system_prompt에 배경 정보 작성 규칙이 포함된다" do
      result = Articles::ContextProviderAgent.call(
        content: "Test",
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "배경"
      assert_includes result.content[:system_prompt], "관련 토픽"
      assert_includes result.content[:system_prompt], "관련 젬"
      assert_includes result.content[:system_prompt], "커뮤니티"
    end

    test "system_prompt에 난이도 분류가 포함된다" do
      result = Articles::ContextProviderAgent.call(
        content: "Test",
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "beginner"
      assert_includes result.content[:system_prompt], "intermediate"
      assert_includes result.content[:system_prompt], "advanced"
    end

    test "temperature가 0.6으로 설정되어 있다" do
      assert_respond_to Articles::ContextProviderAgent, :call
    end
  end
end
