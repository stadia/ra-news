# frozen_string_literal: true

require "test_helper"

class SitemapBuilderTest < ActiveSupport::TestCase
  test "call은 SitemapGenerator를 설정하고 create를 호출한다" do
    create_called = false

    SitemapGenerator::Sitemap.stub(:create, ->(&_block) {
      create_called = true

      assert_equal "https://ruby-news.dev", SitemapGenerator::Sitemap.default_host
      assert_equal "sitemaps/", SitemapGenerator::Sitemap.sitemaps_path
      assert SitemapGenerator::Sitemap.compress
    }) do
      SitemapBuilder.build
    end

    assert create_called, "SitemapGenerator::Sitemap.create가 호출되어야 합니다"
  end

  test "홈 URL은 ko와 ja URL 노드와 hreflang alternates를 모두 가진다" do
    add_calls = []
    sitemap_dsl = Class.new do
      include Rails.application.routes.url_helpers

      define_method(:add) do |path, options|
        add_calls << [ path, options ]
      end
    end.new

    SitemapGenerator::Sitemap.stub(:create, ->(&block) { sitemap_dsl.instance_eval(&block) }) do
      SitemapBuilder.build
    end

    root_calls = add_calls.select { |path, _options| path == "/" }

    assert_equal [ "https://ruby-news.dev", "https://ruby-news.jp" ], root_calls.map { |_path, options| options.fetch(:host) }
    root_calls.each do |_path, options|
      assert_equal [
        { href: "https://ruby-news.dev", lang: "ko" },
        { href: "https://ruby-news.jp", lang: "ja" }
      ], options.fetch(:alternates)
    end
  end

  test "call 메서드는 블록을 create에 전달한다" do
    block_passed = false

    SitemapGenerator::Sitemap.stub(:create, ->(&block) {
      block_passed = block.present?
    }) do
      SitemapBuilder.build
    end

    assert block_passed, "create에 블록이 전달되어야 합니다"
  end

  test "기본 호스트는 ruby-news.dev이다" do
    captured_host = nil

    SitemapGenerator::Sitemap.stub(:default_host=, ->(v) { captured_host = v }) do
      SitemapGenerator::Sitemap.stub(:sitemaps_path=, nil) do
        SitemapGenerator::Sitemap.stub(:compress=, nil) do
          SitemapGenerator::Sitemap.stub(:create, ->(&_) { }) do
            SitemapBuilder.build
          end
        end
      end
    end

    assert_equal "https://ruby-news.dev", captured_host
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

  test "사이트맵 경로는 sitemaps/이다" do
    captured_path = nil

    SitemapGenerator::Sitemap.stub(:default_host=, nil) do
      SitemapGenerator::Sitemap.stub(:sitemaps_path=, ->(v) { captured_path = v }) do
        SitemapGenerator::Sitemap.stub(:compress=, nil) do
          SitemapGenerator::Sitemap.stub(:create, ->(&_) { }) do
            SitemapBuilder.build
          end
        end
      end
    end

    assert_equal "sitemaps/", captured_path
  end

  test "compress는 true로 설정된다" do
    compress_set = false

    SitemapGenerator::Sitemap.stub(:default_host=, nil) do
      SitemapGenerator::Sitemap.stub(:sitemaps_path=, nil) do
        SitemapGenerator::Sitemap.stub(:compress=, ->(v) { compress_set = v }) do
          SitemapGenerator::Sitemap.stub(:create, ->(&_) { }) do
            SitemapBuilder.build
          end
        end
      end
    end

    assert compress_set
  end
end
