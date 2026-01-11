# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

# SitemapService 테스트
# SitemapGenerator를 mock하여 사이트맵 생성 로직을 테스트합니다.
class SitemapServiceTest < ActiveSupport::TestCase
  setup do
    @service = SitemapService.new
  end

  test "call은 SitemapGenerator를 호출하여 사이트맵을 생성한다" do
    create_called = false
    compress_value = nil

    # SitemapGenerator::Sitemap.create 메서드 stub
    SitemapGenerator::Sitemap.stub(:create, ->(*_args, **kwargs, &_block) {
      create_called = true
      # create 옵션 검증
      assert_equal "https://ruby-news.kr", kwargs[:default_host]
      assert_equal "sitemaps/", kwargs[:sitemaps_path]
    }) do
      SitemapGenerator::Sitemap.stub(:compress=, ->(value) {
        compress_value = value
      }) do
        @service.call
      end
    end

    assert create_called, "SitemapGenerator::Sitemap.create가 호출되어야 합니다"
    assert_equal true, compress_value, "compress가 true로 설정되어야 합니다"
  end

  test "서비스는 ApplicationService를 상속한다" do
    assert_kind_of ApplicationService, @service
  end

  test "call 메서드는 블록을 create에 전달한다" do
    block_passed = false

    SitemapGenerator::Sitemap.stub(:create, ->(*_args, **_kwargs, &block) {
      block_passed = block.present?
    }) do
      SitemapGenerator::Sitemap.stub(:compress=, true) do
        @service.call
      end
    end

    assert block_passed, "create에 블록이 전달되어야 합니다"
  end

  test "기본 호스트는 ruby-news.kr이다" do
    captured_host = nil

    SitemapGenerator::Sitemap.stub(:create, ->(*_args, **kwargs, &_block) {
      captured_host = kwargs[:default_host]
    }) do
      SitemapGenerator::Sitemap.stub(:compress=, true) do
        @service.call
      end
    end

    assert_equal "https://ruby-news.kr", captured_host
  end

  test "사이트맵 경로는 sitemaps/이다" do
    captured_path = nil

    SitemapGenerator::Sitemap.stub(:create, ->(*_args, **kwargs, &_block) {
      captured_path = kwargs[:sitemaps_path]
    }) do
      SitemapGenerator::Sitemap.stub(:compress=, true) do
        @service.call
      end
    end

    assert_equal "sitemaps/", captured_path
  end

  test "compress는 true로 설정된다" do
    compress_set = false

    SitemapGenerator::Sitemap.stub(:create, ->(*_args, **_kwargs, &_block) { }) do
      SitemapGenerator::Sitemap.stub(:compress=, ->(value) {
        compress_set = value
      }) do
        @service.call
      end
    end

    assert_equal true, compress_set
  end
end
