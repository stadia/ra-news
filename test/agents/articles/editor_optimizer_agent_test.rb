# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

module Articles
  class EditorOptimizerAgentTest < ActiveSupport::TestCase
    test "에이전트가 ApplicationAgent를 상속한다" do
      assert_operator Articles::EditorOptimizerAgent, :<, ApplicationAgent
    end

    test "title, summary_key, summary_body, content 파라미터가 필수다" do
      assert_raises(ArgumentError) do
        Articles::EditorOptimizerAgent.call(
          summary_key: [ "요약" ],
          summary_body: "본론",
          content: "내용",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::EditorOptimizerAgent.call(
          title: "제목",
          summary_body: "본론",
          content: "내용",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::EditorOptimizerAgent.call(
          title: "제목",
          summary_key: [ "요약" ],
          content: "내용",
          dry_run: true
        )
      end

      assert_raises(ArgumentError) do
        Articles::EditorOptimizerAgent.call(
          title: "제목",
          summary_key: [ "요약" ],
          summary_body: "본론",
          dry_run: true
        )
      end
    end

    test "title_ko는 선택적이다" do
      result = Articles::EditorOptimizerAgent.call(
        title: "Rails 8 Released",
        summary_key: [ "핵심1", "핵심2" ],
        summary_body: "본론 마크다운",
        content: "원본 콘텐츠",
        dry_run: true
      )

      assert_kind_of RubyLLM::Agents::Result, result
      refute_includes result.content[:user_prompt], "Rails 8 출시"
    end

    test "title_ko가 제공되면 프롬프트에 포함된다" do
      result = Articles::EditorOptimizerAgent.call(
        title: "Rails 8 Released",
        title_ko: "Rails 8 출시",
        summary_key: [ "핵심1" ],
        summary_body: "본론",
        content: "내용",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "Rails 8 출시"
    end

    test "summary_key가 번호가 매겨진 목록으로 포맷된다" do
      result = Articles::EditorOptimizerAgent.call(
        title: "Test",
        summary_key: [ "첫 번째", "두 번째" ],
        summary_body: "본론",
        content: "내용",
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "1. 첫 번째"
      assert_includes result.content[:user_prompt], "2. 두 번째"
    end

    test "긴 콘텐츠는 4000자로 제한된다" do
      long_content = "Ruby " * 1000 # 5000자
      result = Articles::EditorOptimizerAgent.call(
        title: "Test",
        summary_key: [ "요약" ],
        summary_body: "본론",
        content: long_content,
        dry_run: true
      )

      assert_includes result.content[:user_prompt], "이하 생략"
    end

    test "system_prompt에 품질 평가 및 승인 기준이 포함된다" do
      result = Articles::EditorOptimizerAgent.call(
        title: "Test",
        summary_key: [ "요약" ],
        summary_body: "본론",
        content: "내용",
        dry_run: true
      )

      assert_includes result.content[:system_prompt], "품질 평가 기준"
      assert_includes result.content[:system_prompt], "relevance"
      assert_includes result.content[:system_prompt], "completeness"
      assert_includes result.content[:system_prompt], "readability"
      assert_includes result.content[:system_prompt], "accuracy"
      assert_includes result.content[:system_prompt], "approved = true"
      assert_includes result.content[:system_prompt], "quality_score"
    end

    test "temperature가 0.2로 설정되어 있다" do
      assert_respond_to Articles::EditorOptimizerAgent, :call
    end
  end
end
