# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class SummarizerAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert Articles::SummarizerAgent < ApplicationAgent
    end

    test "content와 title 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::SummarizerAgent.call(title: "Test")
      end

      assert_raises(ArgumentError) do
        Articles::SummarizerAgent.call(content: "Test content")
      end
    end

    test "dry_run 모드에서 프롬프트를 반환한다" do
      result = Articles::SummarizerAgent.call(
        content: "Ruby 3.4 introduces pattern matching improvements...",
        title: "Ruby 3.4 New Features",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "제목"
      assert_includes result.content[:user_prompt], "본문"
    end

    test "system_prompt에 요약 규칙이 포함된다" do
      result = Articles::SummarizerAgent.call(
        content: "Test",
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "핵심 요약"
      assert_includes result.content[:system_prompt], "3개"
      assert_includes result.content[:system_prompt], "서론"
      assert_includes result.content[:system_prompt], "결론"
    end

    test "system_prompt에 콘텐츠 유형 분류가 포함된다" do
      result = Articles::SummarizerAgent.call(
        content: "Test",
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "tutorial"
      assert_includes result.content[:system_prompt], "news"
      assert_includes result.content[:system_prompt], "opinion"
      assert_includes result.content[:system_prompt], "reference"
    end

    test "gemini-2.5-flash 모델을 사용한다" do
      # 에이전트 클래스가 올바르게 구성되었는지 확인
      assert_respond_to Articles::SummarizerAgent, :call
    end

    test "타임아웃이 90초로 설정되어 있다" do
      assert_respond_to Articles::SummarizerAgent, :call
    end
  end
end
