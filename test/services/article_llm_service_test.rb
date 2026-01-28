# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

class ArticleLlmServiceTest < ActiveSupport::TestCase
  # ArticleLlmService는 복잡한 외부 의존성(RubyLLM, ContentService, embedding)이 있어
  # 테스트 환경에서는 주요 로직만 검증합니다.

  setup do
    @article = articles(:ruby_article)
    @youtube_article = articles(:youtube_ruby_talk)
  end

  # RubyLLM chat mock 생성 헬퍼
  def create_chat_mock(response_content)
    chat_mock = Object.new
    chat_mock.define_singleton_method(:with_temperature) { |_| self }
    chat_mock.define_singleton_method(:with_schema) { |_| self }
    chat_mock.define_singleton_method(:with_instructions) { |_| self }
    chat_mock.define_singleton_method(:add_message) { |**_| self }

    response_mock = Object.new
    response_mock.define_singleton_method(:respond_to?) { |method| method == :content }
    response_mock.define_singleton_method(:content) { response_content }

    chat_mock.define_singleton_method(:ask) { |_| response_mock }
    chat_mock
  end

  # embedding 메서드를 article에 추가하는 헬퍼
  def stub_embedding_for(article)
    article.define_singleton_method(:embedding) { nil }
    article.define_singleton_method(:embedding=) { |_| nil }
  end

  test "서비스가 올바르게 초기화된다" do
    service = ArticleLlmService.new(@article)

    assert_equal @article, service.article
  end

  test "서비스는 ApplicationService를 상속한다" do
    service = ArticleLlmService.new(@article)

    assert_kind_of ApplicationService, service
  end

  test "article body가 없거나 25자 미만일 때 ContentService를 호출한다" do
    article = articles(:ruby_article)
    article.body = nil

    # ContentService가 실패 반환하는 경우를 테스트
    # stub을 사용하지 않고 실제 동작을 시뮬레이션

    # ContentService 인스턴스 생성 후 call 메서드를 stub
    original_new = ContentService.method(:new)

    ContentService.define_singleton_method(:new) do
      instance = original_new.call
      instance.define_singleton_method(:call) { |_| Dry::Monads::Failure(:no_content) }
      instance
    end

    begin
      service = ArticleLlmService.new(article)
      service.call

      # 콘텐츠가 없으면 discard 되어야 함
      assert article.discarded?
    ensure
      # 원래 메서드 복원
      ContentService.define_singleton_method(:new, original_new)
    end
  end

  test "YouTube article 처리 시 YoutubeContent 프롬프트를 사용한다" do
    youtube_article = articles(:youtube_ruby_talk)
    youtube_article.body = "YouTube transcript content that is longer than 25 characters"

    llm_response = {
      "title_ko" => "RubyConf 2024 키노트",
      "summary_key" => [ "요약 1", "요약 2", "요약 3" ],
      "summary_detail" => {
        "introduction" => "서론",
        "body" => "본론",
        "conclusion" => "결론"
      },
      "tags" => [ "rubyconf", "keynote" ],
      "is_related" => true
    }

    ask_called_with = nil

    chat_mock = Object.new
    chat_mock.define_singleton_method(:with_temperature) { |_| self }
    chat_mock.define_singleton_method(:with_schema) { |_| self }
    chat_mock.define_singleton_method(:with_instructions) { |_| self }
    chat_mock.define_singleton_method(:add_message) { |**_| self }
    chat_mock.define_singleton_method(:ask) do |prompt|
      ask_called_with = prompt
      response = Object.new
      response.define_singleton_method(:respond_to?) { |method| method == :content }
      response.define_singleton_method(:content) { llm_response }
      response
    end

    # embedding stub
    stub_embedding_for(youtube_article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(youtube_article)
      service.call
    end

    assert_not_nil ask_called_with
    assert_includes ask_called_with, "YoutubeContent"
  end

  test "일반 기사 처리 시 HtmlContent 프롬프트를 사용한다" do
    article = articles(:ruby_article)
    article.body = "Regular HTML content that is definitely longer than 25 characters"

    llm_response = {
      "title_ko" => "테스트 제목",
      "summary_key" => [ "요약" ],
      "summary_detail" => {
        "introduction" => "서론",
        "body" => "본론",
        "conclusion" => "결론"
      },
      "tags" => [],
      "is_related" => true
    }

    ask_called_with = nil

    chat_mock = Object.new
    chat_mock.define_singleton_method(:with_temperature) { |_| self }
    chat_mock.define_singleton_method(:with_schema) { |_| self }
    chat_mock.define_singleton_method(:with_instructions) { |_| self }
    chat_mock.define_singleton_method(:add_message) { |**_| self }
    chat_mock.define_singleton_method(:ask) do |prompt|
      ask_called_with = prompt
      response = Object.new
      response.define_singleton_method(:respond_to?) { |method| method == :content }
      response.define_singleton_method(:content) { llm_response }
      response
    end

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    assert_not_nil ask_called_with
    assert_includes ask_called_with, "HtmlContent"
  end

  test "LLM 응답이 content를 지원하지 않으면 article이 discard된다" do
    article = articles(:ruby_article)
    article.body = "Some content that is longer than 25 characters for testing"

    # respond_to?(:content)가 false를 반환하는 응답
    response_mock = Object.new
    response_mock.define_singleton_method(:respond_to?) { |method| method != :content }

    chat_mock = Object.new
    chat_mock.define_singleton_method(:with_temperature) { |_| self }
    chat_mock.define_singleton_method(:with_schema) { |_| self }
    chat_mock.define_singleton_method(:with_instructions) { |_| self }
    chat_mock.define_singleton_method(:add_message) { |**_| self }
    chat_mock.define_singleton_method(:ask) { |_| response_mock }

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    assert article.discarded?
  end

  test "LLM 응답 content가 빈 경우 article이 discard된다" do
    article = articles(:ruby_article)
    article.body = "Some content that is longer than 25 characters for testing"

    llm_response = {} # 빈 응답

    chat_mock = create_chat_mock(llm_response)

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    assert article.discarded?
  end

  test "LLM 응답이 올바르게 article 속성을 업데이트한다" do
    article = articles(:ruby_article)
    article.body = "Ruby 3.4 brings exciting new features including improved performance and more."

    llm_response = {
      "title_ko" => "Ruby 3.4의 새로운 기능들",
      "summary_key" => [ "핵심 요약 1", "핵심 요약 2", "핵심 요약 3" ],
      "summary_detail" => {
        "introduction" => "서론입니다.",
        "body" => "본론입니다.",
        "conclusion" => "결론입니다."
      },
      "tags" => [ "ruby", "performance", "syntax" ],
      "is_related" => true
    }

    chat_mock = create_chat_mock(llm_response)

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    article.reload
    assert_equal "Ruby 3.4의 새로운 기능들", article.title_ko
    assert_equal [ "핵심 요약 1", "핵심 요약 2", "핵심 요약 3" ], article.summary_key
    assert_equal "본론입니다.", article.summary_body
    assert article.is_related
  end

  test "is_related가 false이고 특정 client인 경우 article이 discard된다" do
    article = articles(:site_only_article) # hacker_news client
    article.body = "Python programming content that is not related to Ruby at all."

    llm_response = {
      "title_ko" => "파이썬 프로그래밍",
      "summary_key" => [ "요약 1" ],
      "summary_detail" => {
        "introduction" => "서론",
        "body" => "본론",
        "conclusion" => "결론"
      },
      "tags" => [ "python" ],
      "is_related" => false
    }

    chat_mock = create_chat_mock(llm_response)

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    article.reload
    assert article.discarded?, "is_related가 false이고 hacker_news client인 경우 discard 되어야 함"
  end

  test "tags가 배열로 제공되면 tag_list에 추가된다" do
    article = articles(:ruby_article)
    article.body = "Ruby content for tag test that is longer than 25 characters"

    llm_response = {
      "title_ko" => "테스트",
      "summary_key" => [ "요약" ],
      "summary_detail" => {
        "introduction" => "서론",
        "body" => "본론",
        "conclusion" => "결론"
      },
      "tags" => [ "NewTag1", "NewTag2" ],
      "is_related" => true
    }

    chat_mock = create_chat_mock(llm_response)

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    article.reload
    # 새 태그들이 추가되었는지 확인 (소문자로 변환됨)
    assert article.tag_list.include?("newtag1")
    assert article.tag_list.include?("newtag2")
  end

  test "summary_body 마크다운 포맷이 정규화된다" do
    article = articles(:ruby_article)
    article.body = "Ruby content for markdown test that is longer than 25 characters"

    # 정규화가 필요한 마크다운 (\\n은 이스케이프된 개행)
    messy_markdown = "텍스트## 헤더\\n리스트 항목"

    llm_response = {
      "title_ko" => "테스트",
      "summary_key" => [ "요약" ],
      "summary_detail" => {
        "introduction" => "서론",
        "body" => messy_markdown,
        "conclusion" => "결론"
      },
      "tags" => [],
      "is_related" => true
    }

    chat_mock = create_chat_mock(llm_response)

    # embedding stub
    stub_embedding_for(article)

    RubyLLM.stub(:chat, chat_mock) do
      service = ArticleLlmService.new(article)
      service.call
    end

    article.reload
    # \\n이 실제 개행으로 변환되었는지 확인
    refute_includes article.summary_body, "\\n"
  end

  test "PROMPT 상수가 정의되어 있다" do
    assert_not_nil ArticleLlmService::PROMPT
    assert_kind_of String, ArticleLlmService::PROMPT
    assert ArticleLlmService::PROMPT.length > 100
  end
end
