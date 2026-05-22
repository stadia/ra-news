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

  test "run_humanize는 HumanMonolithAgent의 구조화된 응답으로 summary_* 필드를 갱신한다" do
    article = articles(:ruby_article)
    article.update!(
      summary_key: [ "첫 요점", "둘째 요점" ],
      summary_detail: { "introduction" => "도입 문장", "conclusion" => "마무리 문장" },
      summary_body: "원본 요약"
    )

    humanize_response = HumanizeResult.new({
      "summary_key" => [ "다듬은 첫 요점", "다듬은 둘째 요점" ],
      "summary_detail" => { "introduction" => "다듬은 도입 문장", "conclusion" => "다듬은 마무리 문장" },
      "summary_body" => "### 공격 개요\n\n운문 결과 본문입니다.",
      "metrics" => { "change_rate" => 0.18, "grade" => "A" },
      "over_polish_aborted" => false
    })

    captured_prompt = nil
    chat = Object.new
    chat.define_singleton_method(:ask) do |prompt|
      captured_prompt = prompt
      humanize_response
    end

    result = nil
    HumanMonolithAgent.stub(:chat, chat) do
      result = ArticleAgentsService.new.send(:run_humanize, article)
    end

    assert_predicate result, :success?
    assert_includes captured_prompt, "summary_key"
    assert_includes captured_prompt, "도입 문장"
    assert_equal [ "다듬은 첫 요점", "다듬은 둘째 요점" ], article.reload.summary_key
    assert_equal({ "introduction" => "다듬은 도입 문장", "conclusion" => "다듬은 마무리 문장" }, article.summary_detail)
    assert_equal "### 공격 개요\n\n운문 결과 본문입니다.", article.summary_body
  end

  test "run_agents는 태그를 적용하고 escaped summary_body를 정규화한다" do
    article = articles(:ruby_article)
    article.update!(summary_body: nil)

    agent_response = AgentResult.new(nil, build_success_content(tags: [ "RubyConf", "Keynote" ]).merge(
      "summary_body" => "첫 줄\\n둘째 줄"
    ))

    agent = Object.new
    agent.define_singleton_method(:ask) { |_| agent_response }

    result = nil
    ArticleAgent.stub(:new, agent) do
      result = ArticleAgentsService.new.send(:run_agents, article)
    end

    assert_predicate result, :success?
    assert_equal "첫 줄\n둘째 줄", article.reload.summary_body
    assert_includes article.tag_list, "rubyconf"
    assert_includes article.tag_list, "keynote"
  end

  test "run_humanize는 over_polish_aborted=true이면 article을 갱신하지 않고 실패를 반환한다" do
    article = articles(:ruby_article)
    article.update!(summary_body: "원본 요약")

    aborted_response = HumanizeResult.new({
      "summary_key" => [],
      "summary_detail" => {},
      "summary_body" => "원본 요약",
      "over_polish_aborted" => true
    })

    chat = Object.new
    chat.define_singleton_method(:ask) { |_| aborted_response }

    result = nil
    HumanMonolithAgent.stub(:chat, chat) do
      result = ArticleAgentsService.new.send(:run_humanize, article)
    end

    assert_predicate result, :failure?
    assert_equal "원본 요약", article.reload.summary_body
  end
end
