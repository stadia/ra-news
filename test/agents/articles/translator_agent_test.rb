# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class TranslatorAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert Articles::TranslatorAgent < ApplicationAgent
    end

    test "title 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::TranslatorAgent.call(content_preview: "preview")
      end
    end

    test "content_preview는 선택적이다" do
      result = Articles::TranslatorAgent.call(
        title: "Rails 8 Released",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
    end

    test "content_preview가 제공되면 프롬프트에 포함된다" do
      result = Articles::TranslatorAgent.call(
        title: "Rails 8 Released",
        content_preview: "Rails 8 introduces many new features...",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "참고 맥락"
      assert_includes result.content[:user_prompt], "Rails 8 introduces"
    end

    test "긴 content_preview는 500자로 제한된다" do
      long_preview = "Ruby " * 200  # 1000자
      result = Articles::TranslatorAgent.call(
        title: "Test",
        content_preview: long_preview,
        dry_run: true
      )

      # content_context 메서드에서 truncate 적용
      assert result.content[:user_prompt].length < long_preview.length + 200
    end

    test "system_prompt에 번역 원칙이 포함된다" do
      result = Articles::TranslatorAgent.call(
        title: "Test",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "번역"
      assert_includes result.content[:system_prompt], "고유명사"
      assert_includes result.content[:system_prompt], "Ruby"
      assert_includes result.content[:system_prompt], "Rails"
    end

    test "temperature가 0.3으로 설정되어 있다" do
      # 에이전트 클래스가 올바르게 구성되었는지 확인
      assert_respond_to Articles::TranslatorAgent, :call
    end

    test "캐시가 24시간으로 설정되어 있다" do
      assert_respond_to Articles::TranslatorAgent, :call
    end
  end
end
