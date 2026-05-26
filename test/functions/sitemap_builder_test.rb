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
