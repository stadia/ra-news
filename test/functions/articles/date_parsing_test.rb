# frozen_string_literal: true

require "test_helper"

class Articles::DateParsingTest < ActiveSupport::TestCase
  # extract_from_json_ld 분기(Array / @graph / article-type 우선순위)를 고정하는 특성화 테스트.
  def doc_with_json_ld(json)
    Nokogiri::HTML5(
      "<html><head><script type=\"application/ld+json\">#{json}</script></head><body></body></html>"
    )
  end

  test "최상위 JSON-LD 배열에서 datePublished를 가진 항목을 찾는다" do
    json = JSON.generate(
      [
        { "@type" => "WebPage" },
        { "@type" => "NewsArticle", "datePublished" => "2026-03-18T09:15:00+09:00" }
      ]
    )

    result = Articles::DateParsing.json_ld_published_at(doc_with_json_ld(json))

    assert_equal Time.zone.parse("2026-03-18T09:15:00+09:00").to_i, result.to_i
  end

  test "@graph 노드 중 발행일을 가진 노드에서 datePublished를 추출한다" do
    json = JSON.generate(
      {
        "@context" => "https://schema.org",
        "@graph" => [
          { "@type" => "WebSite" },
          { "@type" => "NewsArticle", "datePublished" => "2026-03-18T09:15:00+09:00" }
        ]
      }
    )

    result = Articles::DateParsing.json_ld_published_at(doc_with_json_ld(json))

    assert_equal Time.zone.parse("2026-03-18T09:15:00+09:00").to_i, result.to_i
  end

  test "article 타입 노드의 날짜를 비-article 노드보다 우선한다" do
    json = JSON.generate(
      {
        "@graph" => [
          { "@type" => "WebPage", "datePublished" => "2020-01-01T00:00:00+09:00" },
          { "@type" => "Article", "datePublished" => "2026-03-18T09:15:00+09:00" }
        ]
      }
    )

    result = Articles::DateParsing.json_ld_published_at(doc_with_json_ld(json))

    assert_equal Time.zone.parse("2026-03-18T09:15:00+09:00").to_i, result.to_i
  end

  test "datePublished가 없으면 dateCreated, uploadDate 순으로 폴백한다" do
    json = JSON.generate({ "@type" => "Article", "uploadDate" => "2026-03-18T09:15:00+09:00" })

    result = Articles::DateParsing.json_ld_published_at(doc_with_json_ld(json))

    assert_equal Time.zone.parse("2026-03-18T09:15:00+09:00").to_i, result.to_i
  end

  test "발행일 정보가 없으면 nil을 반환한다" do
    json = JSON.generate({ "@type" => "WebPage" })

    assert_nil Articles::DateParsing.json_ld_published_at(doc_with_json_ld(json))
  end
end
