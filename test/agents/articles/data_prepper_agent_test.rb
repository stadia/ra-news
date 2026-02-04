# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class DataPrepperAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::DataPrepperAgent, :<, ApplicationAgent
    end

    test "raw_content, title, url 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::DataPrepperAgent.call(title: "Test", url: "https://example.com", dry_run: true)
      end

      assert_raises(ArgumentError) do
        Articles::DataPrepperAgent.call(raw_content: "Content", url: "https://example.com", dry_run: true)
      end

      assert_raises(ArgumentError) do
        Articles::DataPrepperAgent.call(raw_content: "Content", title: "Test", dry_run: true)
      end
    end

    test "content_type은 기본값이 html이다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "<p>Test</p>",
        title: "HTML Article",
        url: "https://example.com/article",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "HTML"
    end

    test "content_type이 youtube일 때 프롬프트에 반영된다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "0:00 - Hello",
        title: "YouTube Transcript",
        url: "https://youtube.com/watch?v=123",
        content_type: "youtube",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "YouTube 자막"
    end

    test "content_type이 text일 때 프롬프트에 반영된다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "Plain text content",
        title: "Text Article",
        url: "https://example.com/text",
        content_type: "text",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "텍스트"
    end

    test "dry_run 모드에서 user_prompt를 반환한다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "<div>Test content</div>",
        title: "Sample",
        url: "https://example.com/sample",
        content_type: "html",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "Title:"
      assert_includes result.content[:user_prompt], "URL:"
      assert_includes result.content[:user_prompt], "Raw Content:"
    end

    test "system_prompt에 데이터 정규화 지침이 포함된다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "Test",
        title: "Test",
        url: "https://example.com",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "데이터 전처리 전문가"
      assert_includes result.content[:system_prompt], "노이즈"
      assert_includes result.content[:system_prompt], "Semantic Chunks"
    end

    test "schema가 정의되어 있다" do
      agent = Articles::DataPrepperAgent.new(
        raw_content: "<p>Test</p>",
        title: "Test",
        url: "https://example.com"
      )
      schema = agent.send(:schema)

      assert_not_nil schema
    end
  end
end
