# frozen_string_literal: true

require "test_helper"

class SitemapBuilderTest < ActiveSupport::TestCase
  # add(path, options) 호출을 기록하는 테스트용 DSL 스텁.
  class FakeDsl
    attr_reader :calls

    def initialize
      @calls = []
    end

    def add(path, options)
      @calls << [ path, options ]
    end
  end

  test "build는 도메인별로 자기 완결 LinkSet을 생성한다(.dev=ko, .jp=ja)" do
    captured = []
    fake_link_set = Object.new
    def fake_link_set.create(*); end # 블록 미실행: DB/인터프리터 우회

    SitemapGenerator::LinkSet.stub(:new, ->(**opts) { captured << opts; fake_link_set }) do
      SitemapBuilder.build
    end

    assert_equal 2, captured.size, "로케일(ko/ja)마다 LinkSet이 하나씩 생성되어야 한다"

    ko, ja = captured

    assert_equal "https://ruby-news.dev", ko[:default_host]
    assert_equal "sitemaps/ko/", ko[:sitemaps_path]
    assert_equal "https://ruby-news.jp", ja[:default_host]
    assert_equal "sitemaps/ja/", ja[:sitemaps_path]

    captured.each do |opts|
      assert_equal SitemapBuilder::MAX_SITEMAP_LINKS, opts[:max_sitemap_links]
      assert opts[:compress]
      refute opts[:include_root]
    end
  end

  test "populate(ko)는 정적 페이지를 .dev 호스트로 등재하고 hreflang alternates를 붙인다" do
    dsl = FakeDsl.new
    SitemapBuilder.populate(dsl, "ko", "https://ruby-news.dev", [])

    root = dsl.calls.find { |path, _options| path == "/" }

    assert root, "홈 URL이 등재되어야 한다"
    assert_equal "https://ruby-news.dev", root[1].fetch(:host)
    assert_equal [
      { href: "https://ruby-news.dev", lang: "ko" },
      { href: "https://ruby-news.jp", lang: "ja" }
    ], root[1].fetch(:alternates)
  end

  test "populate(ja)의 <loc>는 .jp 호스트만 가진다" do
    dsl = FakeDsl.new
    SitemapBuilder.populate(dsl, "ja", "https://ruby-news.jp", [])

    hosts = dsl.calls.map { |_path, options| options.fetch(:host) }.uniq

    assert_equal [ "https://ruby-news.jp" ], hosts, "ja 사이트맵의 <loc>는 .jp 호스트만 가진다"
  end

  test "populate는 해당 로케일 번역이 있는 Entry만 등재한다" do
    ko_only = SitemapBuilder::Entry.new(
      path: "/articles/x",
      lastmod: "2026-01-01T00:00:00+09:00",
      available: [ "ko" ],
      alternates: [ { href: "https://ruby-news.dev/articles/x", lang: "ko" } ]
    )

    ko_dsl = FakeDsl.new
    SitemapBuilder.populate(ko_dsl, "ko", "https://ruby-news.dev", [ ko_only ])

    assert_includes ko_dsl.calls.map(&:first), "/articles/x", "ko 번역이 있으면 ko 사이트맵에 등재"

    ja_dsl = FakeDsl.new
    SitemapBuilder.populate(ja_dsl, "ja", "https://ruby-news.jp", [ ko_only ])

    refute_includes ja_dsl.calls.map(&:first), "/articles/x", "ja 번역이 없으면 ja 사이트맵에서 제외"
  end

  test "보조 도메인은 hreflang alternates로 포함한다" do
    assert_equal [
      { href: "https://ruby-news.dev/articles", lang: "ko" },
      { href: "https://ruby-news.jp/articles", lang: "ja" }
    ], SitemapBuilder.alternates_for("/articles")
  end

  test "lastmod는 발행 이후 업데이트 시각을 반영한다" do
    article = Article.new(
      published_at: Time.zone.local(2026, 1, 1, 10, 0, 0),
      updated_at: Time.zone.local(2026, 1, 2, 10, 0, 0)
    )

    assert_equal "2026-01-02T10:00:00+09:00", SitemapBuilder.lastmod_for(article)
  end

  test "lastmod는 비현실적인 published_at 대신 안전한 updated_at을 사용한다" do
    article = Article.new(
      published_at: Time.zone.local(1935, 1, 1, 10, 0, 0),
      updated_at: Time.zone.local(2026, 1, 2, 10, 0, 0)
    )

    assert_equal "2026-01-02T10:00:00+09:00", SitemapBuilder.lastmod_for(article)
  end

  test "lastmod는 미래 시각을 제외한다" do
    article = Article.new(
      published_at: 1.day.from_now,
      updated_at: Time.zone.local(2026, 1, 2, 10, 0, 0)
    )

    assert_equal "2026-01-02T10:00:00+09:00", SitemapBuilder.lastmod_for(article)
  end
end
