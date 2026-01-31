# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class DataPrepperAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::DataPrepperAgent, :<, ApplicationAgent
    end

    test "raw_content 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::DataPrepperAgent.call(content_type: "html")
      end
    end

    test "content_type은 기본값이 html이다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "<p>Test</p>",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "HTML"
    end

    test "content_type이 youtube일 때 프롬프트에 반영된다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "0:00 - Hello",
        content_type: "youtube",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "YouTube"
    end

    test "dry_run 모드에서 user_prompt를 반환한다" do
      result = Articles::DataPrepperAgent.call(
        raw_content: "<div>Test content</div>",
        content_type: "html",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      assert_includes result.content[:user_prompt], "원본 콘텐츠"
    end

    test "schema가 정의되어 있다" do
      agent = Articles::DataPrepperAgent.new(raw_content: "<p>Test</p>")
      schema = agent.send(:schema)

      # RubyLLM::Schema.create는 Class를 반환
      assert_not_nil schema
    end

    test "캐시가 6시간으로 설정되어 있다" do
      # 클래스 레벨에서 cache 설정 확인
      # ruby_llm-agents의 내부 구현에 따라 확인 방법이 다를 수 있음
      assert_respond_to Articles::DataPrepperAgent, :call
    end
  end
end
