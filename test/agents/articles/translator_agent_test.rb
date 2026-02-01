# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class TranslatorAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::TranslatorAgent, :<, ApplicationAgent
    end

    test "title, summary_key, summary_detail, summary_body 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::TranslatorAgent.call(
          summary_key: [ "요약" ],
          summary_detail: { introduction: "intro", conclusion: "outro" },
          summary_body: "body",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TranslatorAgent.call(
          title: "Test",
          summary_detail: { introduction: "intro", conclusion: "outro" },
          summary_body: "body",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TranslatorAgent.call(
          title: "Test",
          summary_key: [ "요약" ],
          summary_body: "body",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::TranslatorAgent.call(
          title: "Test",
          summary_key: [ "요약" ],
          summary_detail: { introduction: "intro", conclusion: "outro" },
          dry_run: true
        )
      end
    end

    test "dry_run 모드에서 프롬프트를 반환한다" do
      result = Articles::TranslatorAgent.call(
        title: "Rails 8 Released",
        summary_key: [ "Key point 1", "Key point 2", "Key point 3" ],
        summary_detail: { introduction: "Intro text", conclusion: "Conclusion text" },
        summary_body: "## Body\n\nDetails here.",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "Title (제목)"
      assert_includes result.content[:user_prompt], "Summary Key"
      assert_includes result.content[:user_prompt], "Body (본론)"
      assert_includes result.content[:user_prompt], "Conclusion (결론)"
    end

    test "summary_key가 번호가 매겨진 목록으로 포맷된다" do
      result = Articles::TranslatorAgent.call(
        title: "Test",
        summary_key: [ "First", "Second" ],
        summary_detail: { introduction: "Intro", conclusion: "Conclusion" },
        summary_body: "Body",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "1. First"
      assert_includes result.content[:user_prompt], "2. Second"
    end

    test "system_prompt에 번역 원칙이 포함된다" do
      result = Articles::TranslatorAgent.call(
        title: "Test",
        summary_key: [ "Key" ],
        summary_detail: { introduction: "Intro", conclusion: "Conclusion" },
        summary_body: "Body",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "기술 번역가"
      assert_includes result.content[:system_prompt], "Translation Principles"
      assert_includes result.content[:system_prompt], "마크다운 보존"
    end

    test "schema가 정의되어 있다" do
      agent = Articles::TranslatorAgent.new(
        title: "Test",
        summary_key: [ "Key" ],
        summary_detail: { introduction: "Intro", conclusion: "Conclusion" },
        summary_body: "Body"
      )
      schema = agent.send(:schema)

      assert_not_nil schema
    end

    test "temperature와 timeout 설정이 존재한다" do
      assert_respond_to Articles::TranslatorAgent, :call
    end
  end
end
