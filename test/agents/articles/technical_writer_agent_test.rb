# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class TechnicalWriterAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert Articles::TechnicalWriterAgent < ApplicationAgent
    end

    test "content, summary_key, title 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          summary_key: ["요약1"],
          title: "Test"
        )
      end

      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          content: "Content",
          title: "Test"
        )
      end

      assert_raises(ArgumentError) do
        Articles::TechnicalWriterAgent.call(
          content: "Content",
          summary_key: ["요약1"]
        )
      end
    end

    test "context는 선택적이다" do
      result = Articles::TechnicalWriterAgent.call(
        content: "Original content",
        summary_key: ["핵심1", "핵심2", "핵심3"],
        title: "Test Article",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      refute_includes result.content[:user_prompt], "배경 정보"
    end

    test "context가 제공되면 프롬프트에 포함된다" do
      result = Articles::TechnicalWriterAgent.call(
        content: "Original content",
        summary_key: ["핵심1", "핵심2", "핵심3"],
        title: "Test Article",
        context: "This is background context",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "배경 정보"
      assert_includes result.content[:user_prompt], "background context"
    end

    test "summary_key가 번호가 매겨진 목록으로 포맷된다" do
      result = Articles::TechnicalWriterAgent.call(
        content: "Content",
        summary_key: ["첫 번째 핵심", "두 번째 핵심", "세 번째 핵심"],
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "1. 첫 번째 핵심"
      assert_includes result.content[:user_prompt], "2. 두 번째 핵심"
      assert_includes result.content[:user_prompt], "3. 세 번째 핵심"
    end

    test "긴 콘텐츠는 10000자로 제한된다" do
      long_content = "Ruby " * 2500  # 12500자
      result = Articles::TechnicalWriterAgent.call(
        content: long_content,
        summary_key: ["요약"],
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "이하 생략"
    end

    test "system_prompt에 마크다운 작성 규칙이 포함된다" do
      result = Articles::TechnicalWriterAgent.call(
        content: "Test",
        summary_key: ["요약"],
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "마크다운"
      assert_includes result.content[:system_prompt], "400-800자"
      assert_includes result.content[:system_prompt], "코드"
    end

    test "gemini-2.5-flash 모델을 사용한다" do
      assert_respond_to Articles::TechnicalWriterAgent, :call
    end

    test "타임아웃이 120초로 설정되어 있다" do
      assert_respond_to Articles::TechnicalWriterAgent, :call
    end
  end
end
