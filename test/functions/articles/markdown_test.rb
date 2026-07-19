# frozen_string_literal: true

require "test_helper"

# Direct coverage for the extracted Articles::Markdown renderer. The happy path
# is also exercised via Article#to_markdown in article_test.rb; these tests pin
# the section-omission and type-guard branches that only live in this module.
class Articles::MarkdownTest < ActiveSupport::TestCase
  def build_article(**overrides)
    Article.new({
      title: "Test Title",
      title_ko: "테스트 제목",
      url: "https://example.com/test",
      origin_url: "https://example.com/test",
      host: "example.com",
      slug: "test-slug",
      summary_key: [ "핵심 요약 1", "핵심 요약 2" ],
      summary_detail: { "introduction" => "서론 부분", "conclusion" => "결론 부분" },
      body: "원본 본문",
      summary_body: "요약된 마크다운 본문",
      user: users(:john)
    }.merge(overrides))
  end

  test "render includes title, source url and ruby-news url" do
    markdown = Articles::Markdown.render(build_article)

    assert_match "# 테스트 제목", markdown
    assert_match "- **원문 URL**: https://example.com/test", markdown
    assert_match "- **Ruby-News URL**: #{Rails.application.routes.url_helpers.article_url(build_article)}", markdown
  end

  test "render includes published_at line when present" do
    markdown = Articles::Markdown.render(build_article(published_at: Time.zone.parse("2026-01-02 03:04:05")))

    assert_match(/- \*\*발행일\*\*: .*2026/, markdown)
  end

  test "render omits published_at line when blank" do
    markdown = Articles::Markdown.render(build_article(published_at: nil))

    assert_no_match(/\*\*발행일\*\*/, markdown)
  end

  test "render omits summary section when summary_key is blank" do
    markdown = Articles::Markdown.render(build_article(summary_key: nil, summary_key_ja: nil))

    assert_no_match(/## 요약/, markdown)
  end

  test "render omits body section when summary_body is blank" do
    markdown = Articles::Markdown.render(build_article(summary_body: nil, summary_body_ja: nil))

    assert_no_match(/## 본문/, markdown)
  end

  # summary_detail is polymorphic; introduction/conclusion only render for a Hash.
  test "render omits introduction and conclusion when summary_detail is not a Hash" do
    markdown = Articles::Markdown.render(build_article(summary_detail: "플레인 문자열"))

    assert_no_match(/## 소개/, markdown)
    assert_no_match(/## 결론/, markdown)
  end

  test "render omits introduction when the introduction key is blank" do
    markdown = Articles::Markdown.render(build_article(summary_detail: { "conclusion" => "결론만" }))

    assert_no_match(/## 소개/, markdown)
    assert_match(/## 결론\n결론만/, markdown)
  end
end
