# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

class ArticleAgentsServiceTest < ActiveSupport::TestCase
  AgentResult = Struct.new(:status, :content)

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
end
