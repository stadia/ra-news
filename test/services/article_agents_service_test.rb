# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

class ArticleAgentsServiceTest < ActiveSupport::TestCase
  AgentResult = Struct.new(:status, :content)
  HumanizeResult = Struct.new(:content)

  def build_success_content(tags: [ "rubyconf", "keynote" ], is_related: true)
    {
      title_ko: "테스트 제목",
      summary_key: [ "요약 1", "요약 2" ],
      summary_detail: {
        introduction: "서론",
        body: "본문",
        conclusion: "결론"
      },
      tags: tags,
      is_related: is_related
    }
  end

  test "서비스는 OperationService를 상속한다" do
    service = ArticleAgentsService.new

    assert_kind_of OperationService, service
  end

  test "body가 없으면 ContentService 실패를 반환하고 discard한다" do
    article = articles(:ruby_article)
    article.update!(body: nil)

    content_service = Object.new
    content_service.define_singleton_method(:call) { |_article = nil| Dry::Monads::Failure(:no_content) }

    result = nil
    ContentService.stub(:new, -> { content_service }) do
      result = ArticleAgentsService.new.call(article)
    end

    assert_predicate result, :failure?
    assert_equal :no_content, result.failure
    assert_predicate article.reload, :discarded?
  end

  test "run_humanize는 summary_key, summary_detail, summary_body를 함께 윤문한다" do
    article = articles(:ruby_article)
    article.update!(
      summary_key: [ "첫 요점", "둘째 요점" ],
      summary_detail: { "introduction" => "도입 문장", "conclusion" => "마무리 문장" },
      summary_body: "원본 요약"
    )

    humanize_response = <<~TEXT
      <<<SUMMARY_KEY>>>
      - 다듬은 첫 요점
      - 다듬은 둘째 요점
      <<<END_SUMMARY_KEY>>>

      <<<SUMMARY_DETAIL:introduction>>>
      다듬은 도입 문장
      <<<END_SUMMARY_DETAIL:introduction>>>

      <<<SUMMARY_DETAIL:conclusion>>>
      다듬은 마무리 문장
      <<<END_SUMMARY_DETAIL:conclusion>>>

      <<<SUMMARY_BODY>>>
      ```
      humanize-korean v1.5 — fast 모드 / run_id: 2025-07-09-001
      ```

      ### 공격 개요

      운문 결과 본문입니다.

      ## 요약

      완료.
      <<<END_SUMMARY_BODY>>>
    TEXT

    captured_prompt = nil
    chat = Object.new
    chat.define_singleton_method(:with_skills) { self }
    chat.define_singleton_method(:ask) do |prompt|
      captured_prompt = prompt
      HumanizeResult.new(humanize_response)
    end

    result = nil
    RubyLLM.stub(:chat, ->(**) { chat }) do
      result = ArticleAgentsService.new.send(:run_humanize, article)
    end

    assert_predicate result, :success?
    assert_includes captured_prompt, "<<<SUMMARY_KEY>>>"
    assert_includes captured_prompt, "<<<SUMMARY_DETAIL:introduction>>>"
    assert_includes captured_prompt, "<<<SUMMARY_BODY>>>"
    assert_equal [ "다듬은 첫 요점", "다듬은 둘째 요점" ], article.reload.summary_key
    assert_equal({ "introduction" => "다듬은 도입 문장", "conclusion" => "다듬은 마무리 문장" }, article.summary_detail)
    assert_equal "### 공격 개요\n\n운문 결과 본문입니다.", article.summary_body
  end

  test "ArticleHumanizer.extract_body는 윤문 결과 헤더가 없으면 원문을 그대로 반환한다" do
    assert_equal "그대로 유지", ArticleHumanizer.extract_body("그대로 유지")
  end

  test "ArticleHumanizer.extract_content는 태그 블록을 파싱한다" do
    content = <<~TEXT
      <<<SUMMARY_KEY>>>
      - 첫 요점
      - 둘째 요점
      <<<END_SUMMARY_KEY>>>

      <<<SUMMARY_DETAIL:introduction>>>
      도입 문장
      <<<END_SUMMARY_DETAIL:introduction>>>

      <<<SUMMARY_BODY>>>
      본문입니다.
      <<<END_SUMMARY_BODY>>>
    TEXT

    result = ArticleHumanizer.extract_content(content)

    assert_equal [ "첫 요점", "둘째 요점" ], result[:summary_key]
    assert_equal({ "introduction" => "도입 문장" }, result[:summary_detail])
    assert_equal "본문입니다.", result[:summary_body]
  end

  test "ArticleHumanizer.extract_body는 메타데이터 코드펜스와 요약 섹션을 제거한다" do
    content = <<~TEXT
      ```
      humanize-korean v1.5 — fast 모드 / run_id: 2025-07-09-001
      ```

      ### 공격 개요

      운문 결과 본문입니다.

      ## 요약

      완료.
    TEXT

    assert_equal "### 공격 개요\n\n운문 결과 본문입니다.", ArticleHumanizer.extract_body(content)
  end

  test "ArticleHumanizer.extract_body는 구분선과 메타 헤딩을 제거한다" do
    content = <<~TEXT
      humanize-korean v1.5 — fast 모드 / run_id: 2025-07-09-001

      ---

      ## 윤문 결과

      본문 첫 문단입니다.

      | 항목 | 내용 |
      |---|---|
      | 장르 | 리포트 |
    TEXT

    assert_equal "본문 첫 문단입니다.", ArticleHumanizer.extract_body(content)
  end
end
