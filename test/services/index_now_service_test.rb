# frozen_string_literal: true

require "test_helper"

class IndexNowServiceTest < ActiveSupport::TestCase
  setup do
    @service = IndexNowService.new
  end

  test "urls가 비어 있으면 API를 호출하지 않는다" do
    called = false
    Faraday.stub(:post, ->(*) { called = true; Struct.new(:status, :body).new(200, "") }) do
      @service.call(host: "ruby-news.dev", urls: [])
    end

    assert_not called, "빈 urls로 Faraday.post가 호출되면 안 됨"
  end

  test "Hosts::INDEX_NOW_KEY가 비어 있으면 API를 호출하지 않는다" do
    called = false
    Faraday.stub(:post, ->(*) { called = true; Struct.new(:status, :body).new(200, "") }) do
      original = Hosts::INDEX_NOW_KEY
      Hosts.send(:remove_const, :INDEX_NOW_KEY)
      Hosts.const_set(:INDEX_NOW_KEY, "")
      begin
        @service.call(host: "ruby-news.dev", urls: [ "https://ruby-news.dev/articles/x" ])
      ensure
        Hosts.send(:remove_const, :INDEX_NOW_KEY)
        Hosts.const_set(:INDEX_NOW_KEY, original)
      end
    end

    assert_not called
  end

  test "200/202 응답은 성공으로 로깅한다" do
    Faraday.stub(:post, ->(*) { Struct.new(:status, :body).new(202, "") }) do
      assert_nothing_raised { @service.call(host: "ruby-news.jp", urls: [ "https://ruby-news.jp/articles/x" ]) }
    end
  end

  test "422 응답은 에러 로깅하고 raise하지 않는다" do
    Faraday.stub(:post, ->(*) { Struct.new(:status, :body).new(422, "bad key") }) do
      assert_nothing_raised { @service.call(host: "ruby-news.dev", urls: [ "https://ruby-news.dev/articles/x" ]) }
    end
  end

  test "Faraday 예외는 에러 로깅하고 raise하지 않는다" do
    Faraday.stub(:post, ->(*) { raise Faraday::ConnectionFailed, "timeout" }) do
      assert_nothing_raised { @service.call(host: "ruby-news.dev", urls: [ "https://ruby-news.dev/articles/x" ]) }
    end
  end

  test "host에 따라 keyLocation가 올바르게 파생된다" do
    captured = nil
    Faraday.stub(:post, lambda { |url, body, _headers = nil|
      payload = JSON.parse(body)
      captured = payload
      Struct.new(:status, :body).new(200, "")
    }) do
      @service.call(host: "ruby-news.jp", urls: [ "https://ruby-news.jp/articles/x" ])
    end

    assert_equal "ruby-news.jp", captured["host"]
    assert_equal Hosts::INDEX_NOW_KEY, captured["key"]
    assert_equal "https://ruby-news.jp/#{Hosts::INDEX_NOW_KEY}.txt", captured["keyLocation"]
    assert_equal [ "https://ruby-news.jp/articles/x" ], captured["urlList"]
  end
end
