# frozen_string_literal: true

require "test_helper"

class GeoStaticFilesTest < ActionDispatch::IntegrationTest
  test "llms txt exposes about page topic hubs and article schema notes" do
    get "/llms.txt"

    assert_response :success
    body = response.body.force_encoding("UTF-8")
    assert_includes body, "[소개 / About](https://ruby-news.dev/about):"
    assert_includes body, "## Topic Hubs"
    assert_includes body, "https://ruby-news.jp"
    assert_includes body, "NewsArticle JSON-LD"
  end

  test "robots txt keeps citation input allowed while blocking training crawlers" do
    get "/robots.txt"

    assert_response :success
    body = response.body.force_encoding("UTF-8")
    assert_includes body, "Content-Signal: search=yes, ai-input=yes, ai-train=no"
    assert_equal 1, body.scan(/^User-agent: \*$/).size
    assert_includes body, "User-agent: PerplexityBot\nAllow: /"
    assert_includes body, "User-agent: GPTBot\nDisallow: /"
    assert_includes body, "User-agent: ClaudeBot\nDisallow: /"
  end
end
