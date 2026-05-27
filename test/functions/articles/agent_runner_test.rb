# frozen_string_literal: true

require "test_helper"

class Articles::AgentRunnerTest < ActiveSupport::TestCase
  Message = Struct.new(:content, :finish_reason)
  SiteStub = Struct.new(:client)

  class TagListStub
    attr_reader :added

    def initialize
      @added = []
    end

    def add(*tags)
      @added.concat(tags)
    end
  end

  class ArticleStub
    attr_reader :id, :tag_list, :site, :updated_content
    attr_accessor :discarded

    def initialize(site_client: "rss")
      @id = 123
      @tag_list = TagListStub.new
      @site = SiteStub.new(site_client)
      @discarded = false
    end

    def update!(attrs)
      @updated_content = attrs
    end

    def discard!
      @discarded = true
    end
  end

  class AgentStub
    def initialize(message)
      @message = message
    end

    def ask(_prompt)
      @message
    end
  end

  test "문자열 tags도 안전하게 처리한다" do
    article = ArticleStub.new
    message = Message.new({ tags: "Ruby", summary_body: "body" }, "stop")

    ArticleAgent.stub(:new, AgentStub.new(message)) do
      result = Articles::AgentRunner.run(article:, prompt: "prompt")

      assert_equal article, result
    end

    assert_equal ["ruby"], article.tag_list.added
    assert_equal({ "summary_body" => "body" }, article.updated_content)
    refute article.discarded
  end

  test "blank 또는 비문자열 tags는 무시하고 유효한 tag만 추가한다" do
    article = ArticleStub.new
    message = Message.new({ tags: ["Ruby", nil, " ", :Rails, { bad: true }], summary_body: "body" }, "stop")

    ArticleAgent.stub(:new, AgentStub.new(message)) do
      result = Articles::AgentRunner.run(article:, prompt: "prompt")

      assert_equal article, result
    end

    assert_equal %w[ruby rails], article.tag_list.added
    assert_equal({ "summary_body" => "body" }, article.updated_content)
    refute article.discarded
  end
end
