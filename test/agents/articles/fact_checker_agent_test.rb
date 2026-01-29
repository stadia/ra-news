# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class FactCheckerAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert Articles::FactCheckerAgent < ApplicationAgent
    end

    test "content와 title 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::FactCheckerAgent.call(title: "Test")
      end

      assert_raises(ArgumentError) do
        Articles::FactCheckerAgent.call(content: "Test content")
      end
    end

    test "url 파라미터는 선택적이다" do
      result = Articles::FactCheckerAgent.call(
        content: "Ruby Rails content",
        title: "Ruby News",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
    end

    test "url이 제공되면 프롬프트에 포함된다" do
      result = Articles::FactCheckerAgent.call(
        content: "Ruby Rails content",
        title: "Ruby News",
        url: "https://example.com/ruby",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "https://example.com/ruby"
    end

    test "긴 콘텐츠는 8000자로 제한된다" do
      long_content = "Ruby " * 2000  # 10000자 이상
      result = Articles::FactCheckerAgent.call(
        content: long_content,
        title: "Test",
        dry_run: true
      )

      # truncate 메시지 확인
      assert_includes result.content[:user_prompt], "이하 생략"
    end

    test "system_prompt에 관련성 판단 기준이 포함된다" do
      result = Articles::FactCheckerAgent.call(
        content: "Test",
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "Ruby"
      assert_includes result.content[:system_prompt], "Rails"
      assert_includes result.content[:system_prompt], "TRUE"
      assert_includes result.content[:system_prompt], "FALSE"
    end

    test "캐시가 12시간으로 설정되어 있다" do
      assert_respond_to Articles::FactCheckerAgent, :call
    end
  end
end
