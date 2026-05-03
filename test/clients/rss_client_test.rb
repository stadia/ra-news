# frozen_string_literal: true

require "test_helper"
require "rss"

class RssClientTest < ActiveSupport::TestCase
  cover RssClient

  test "RssClient는 모듈이다" do
    assert_kind_of Module, RssClient
  end

  test "feed 싱글톤 메서드를 가진다" do
    assert_respond_to RssClient, :feed
  end

  test "정상 RSS XML을 파싱한다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <item>
            <title>Hello</title>
            <link>https://example.com/1</link>
          </item>
        </channel>
      </rss>
    XML

    result = RssClient.parse(xml)

    assert_kind_of RSS::Rss, result
    assert_equal "Test Feed", result.channel.title
  end

  test "content 네임스페이스 누락 XML도 파싱한다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Broken Feed</title>
          <item>
            <title>Hello</title>
            <content:encoded><![CDATA[<p>Body</p>]]></content:encoded>
          </item>
        </channel>
      </rss>
    XML

    result = RssClient.parse(xml)

    assert_kind_of RSS::Rss, result
    assert_equal "Broken Feed", result.channel.title
  end

  test "dc 네임스페이스 누락 XML도 파싱한다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>DC Feed</title>
          <item>
            <title>Hello</title>
            <dc:creator>John</dc:creator>
          </item>
        </channel>
      </rss>
    XML

    result = RssClient.parse(xml)

    assert_kind_of RSS::Rss, result
    assert_equal "DC Feed", result.channel.title
  end

  test "여러 네임스페이스가 누락된 XML도 파싱한다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Multi NS Feed</title>
          <item>
            <title>Hello</title>
            <content:encoded>Body</content:encoded>
            <dc:creator>John</dc:creator>
            <media:content url="https://example.com/img.jpg"/>
          </item>
        </channel>
      </rss>
    XML

    result = RssClient.parse(xml)

    assert_kind_of RSS::Rss, result
    assert_equal "Multi NS Feed", result.channel.title
  end

  test "알 수 없는 네임스페이스 접두어도 파싱한다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Unknown NS Feed</title>
          <item>
            <title>Hello</title>
            <custom:tag>Value</custom:tag>
          </item>
        </channel>
      </rss>
    XML

    result = RssClient.parse(xml)

    assert_kind_of RSS::Rss, result
    assert_equal "Unknown NS Feed", result.channel.title
  end

  test "well-formed XML은 repair_xml을 호출하지 않는다" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel>
          <title>Good Feed</title>
          <item>
            <title>Hello</title>
            <content:encoded>Body</content:encoded>
          </item>
        </channel>
      </rss>
    XML

    RssClient.stub(:repair_xml, ->(_) { flunk "repair_xml should not be called" }) do
      result = RssClient.parse(xml)

      assert_kind_of RSS::Rss, result
    end
  end
end
