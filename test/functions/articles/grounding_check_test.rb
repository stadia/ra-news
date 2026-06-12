# frozen_string_literal: true

require "test_helper"

class Articles::GroundingCheckTest < ActiveSupport::TestCase
  Message = Struct.new(:content)

  ArticleStub = Struct.new(
    :id, :body, :summary_key, :summary_introduction, :summary_body, :summary_conclusion,
    keyword_init: true
  )

  def article(**overrides)
    defaults = {
      id: 1, body: "원문 본문입니다. Rails 8이 async query를 도입했다.",
      summary_key: [ "Rails 8 async query 도입" ],
      summary_introduction: "Rails 8 배경",
      summary_body: "Rails 8은 async query를 도입했다.",
      summary_conclusion: "정리"
    }
    ArticleStub.new(**defaults.merge(overrides))
  end

  def stub_agent(content)
    agent = Object.new
    agent.define_singleton_method(:ask) { |_prompt| Message.new(content) }
    agent
  end

  test "근거 충분(score >= THRESHOLD)이면 flagged=false로 결과를 반환한다" do
    content = { "grounded" => true, "score" => 0.95, "unsupported_claims" => [] }
    result = GroundingAgent.stub(:new, stub_agent(content)) do
      Articles::GroundingCheck.run(article)
    end

    assert_in_delta 0.95, result[:grounding_score], 1e-9
    refute result[:grounding_flagged]
    assert_equal [], result[:grounding_issues]
    assert_kind_of Time, result[:grounding_checked_at]
  end

  test "근거 부족(score < THRESHOLD)이면 flagged=true와 issues를 반환한다" do
    issues = [ { "claim" => "없는 사실", "field" => "summary_body", "reason" => "원문에 없음" } ]
    content = { "grounded" => false, "score" => 0.4, "unsupported_claims" => issues }
    result = GroundingAgent.stub(:new, stub_agent(content)) do
      Articles::GroundingCheck.run(article)
    end

    assert result[:grounding_flagged]
    assert_equal issues, result[:grounding_issues]
  end

  test "score가 정확히 THRESHOLD면 flagged=false다" do
    content = { "grounded" => true, "score" => Articles::GroundingCheck::THRESHOLD, "unsupported_claims" => [] }
    result = GroundingAgent.stub(:new, stub_agent(content)) do
      Articles::GroundingCheck.run(article)
    end

    refute result[:grounding_flagged]
  end

  test "judge 호출이 예외를 던지면 nil을 반환한다(비차단)" do
    agent = Object.new
    agent.define_singleton_method(:ask) { |_prompt| raise "boom" }
    result = GroundingAgent.stub(:new, agent) do
      Articles::GroundingCheck.run(article)
    end

    assert_nil result
  end

  test "원문이나 요약이 모두 비면 검증을 생략하고 nil을 반환한다" do
    blank = article(body: "", summary_key: [], summary_introduction: nil, summary_body: nil, summary_conclusion: nil)
    called = false
    agent = Object.new
    agent.define_singleton_method(:ask) { |_| called = true; Message.new({}) }

    result = GroundingAgent.stub(:new, agent) do
      Articles::GroundingCheck.run(blank)
    end

    assert_nil result
    refute called, "검증을 호출하면 안 된다"
  end
end
