# frozen_string_literal: true

require "test_helper"

class RssHelperTest < ActiveSupport::TestCase
  class TestHost
    include RssHelper

    attr_reader :warnings

    def initialize
      @warnings = []
    end

    def logger
      @logger ||= Object.new.tap do |test_logger|
        warnings = @warnings
        test_logger.define_singleton_method(:warn) { |message| warnings << message }
      end
    end

    public :extract_item_attributes, :feed_items, :fetch_feed
  end

  test "RSS 1.0 RDF 피드는 빈 배열 대신 피드 항목을 반환한다" do
    feed = RSS::Parser.parse(<<~XML, false)
      <?xml version="1.0"?>
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://purl.org/rss/1.0/">
        <channel rdf:about="https://example.com/">
          <title>Example</title>
          <link>https://example.com/</link>
          <description>Example feed</description>
          <items>
            <rdf:Seq><rdf:li rdf:resource="https://example.com/articles/1" /></rdf:Seq>
          </items>
        </channel>
        <item rdf:about="https://example.com/articles/1">
          <title>RDF article</title>
          <link>https://example.com/articles/1</link>
          <description>Article body</description>
        </item>
      </rdf:RDF>
    XML
    host = TestHost.new

    assert_instance_of RSS::RDF, feed
    assert_equal feed.items, host.feed_items(feed)
    travel_to Time.zone.parse("2026-08-08 12:00:00") do
      assert_equal(
        {
          title: "RDF article",
          url: "https://example.com/articles/1",
          origin_url: "https://example.com/articles/1",
          published_at: Time.zone.now
        },
        host.extract_item_attributes(feed.items.first)
      )
    end
  end

  test "URL이 없는 사이트는 스킵 사유를 경고 로그에 남긴다" do
    site = Site.new(name: "URL 없음", url: nil)
    host = TestHost.new

    assert_nil host.fetch_feed(site)
    assert_includes host.warnings, "RSS site #{site.id} (#{site.name}) has no URL; skipping fetch"
  end
end
