# typed: false
# frozen_string_literal: true

require "test_helper"

module Rss
  class PageCrawlerTest < ActiveSupport::TestCase
    MockResponse = Struct.new(:status, :body)

    setup do
      @site = sites(:hacker_news_ruby)
    end

    test "feed가 nil이면 Article을 생성하지 않는다" do
      Rss::PageCrawler.stub(:fetch_feed, nil) do
        assert_no_difference("Article.count") do
          Rss::PageCrawler.crawl(@site)
        end
      end
    end

    test "feed_items가 비어 있으면 Faraday.get을 호출하지 않는다" do
      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, []) do
          Faraday.stub(:get, ->(*) { raise "Faraday.get should not be called" }) do
            assert_no_difference("Article.count") do
              Rss::PageCrawler.crawl(@site)
            end
          end
        end
      end
    end

    test "site.last_checked_at 이전 published_at은 필터링되어 Faraday.get을 호출하지 않는다" do
      old_attr = { url: "https://example.com/old", published_at: 10.days.ago, origin_url: "https://example.com/old" }

      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, [ :item ]) do
          Rss::PageCrawler.stub(:extract_item_attributes, old_attr) do
            Faraday.stub(:get, ->(*) { raise "filtered items should not be fetched" }) do
              assert_no_difference("Article.count") do
                Rss::PageCrawler.crawl(@site)
              end
            end
          end
        end
      end
    end

    test "pdf URL은 Faraday.get을 호출하지 않는다" do
      pdf_attr = { url: "https://example.com/file.pdf", published_at: Time.zone.now, origin_url: "https://example.com/file.pdf" }

      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, [ :item ]) do
          Rss::PageCrawler.stub(:extract_item_attributes, pdf_attr) do
            Faraday.stub(:get, ->(*) { raise "pdf url should not be fetched" }) do
              assert_no_difference("Article.count") do
                Rss::PageCrawler.crawl(@site)
              end
            end
          end
        end
      end
    end

    test "url이 비어 있으면 Faraday.get을 호출하지 않는다" do
      blank_url_attr = { url: nil, published_at: Time.zone.now, origin_url: "https://example.com/list" }

      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, [ :item ]) do
          Rss::PageCrawler.stub(:extract_item_attributes, blank_url_attr) do
            Faraday.stub(:get, ->(*) { raise "blank url should not be fetched" }) do
              assert_no_difference("Article.count") do
                Rss::PageCrawler.crawl(@site)
              end
            end
          end
        end
      end
    end

    test "published_at이 nil이어도 필터링 중 예외가 나지 않는다" do
      @site.last_checked_at = Time.zone.now
      undated_attr = { url: "https://example.com/list", published_at: nil, origin_url: "https://example.com/list" }
      fetched = false

      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, [ :item ]) do
          Rss::PageCrawler.stub(:extract_item_attributes, undated_attr) do
            Faraday.stub(:get, ->(*) { fetched = true; MockResponse.new(404, "") }) do
              assert_no_difference("Article.count") do
                Rss::PageCrawler.crawl(@site)
              end
            end
          end
        end
      end

      assert fetched, "published_at이 nil이어도 링크 수집 단계까지 진행되어야 합니다"
    end

    test "링크 수집 중 예외가 발생해도 crawl은 중단되지 않는다" do
      list_attr = { url: "https://example.com/list", published_at: Time.zone.now, origin_url: "https://example.com/list" }

      Rss::PageCrawler.stub(:fetch_feed, Object.new) do
        Rss::PageCrawler.stub(:feed_items, [ :item ]) do
          Rss::PageCrawler.stub(:extract_item_attributes, list_attr) do
            Faraday.stub(:get, ->(*) { raise Faraday::ConnectionFailed, "timeout" }) do
              assert_no_difference("Article.count") do
                Rss::PageCrawler.crawl(@site)
              end
            end
          end
        end
      end
    end

    test "이미 존재하는 origin_url은 Article을 새로 만들지 않는다" do
      existing = articles(:ruby_article).origin_url
      list_attr = { url: "https://example.com/list", published_at: Time.zone.now, origin_url: "https://example.com/list" }
      html_body = %(<html><body><a href="#{existing}">link</a></body></html>)
      response = MockResponse.new(200, html_body)

      Articles::Utils.stub(:should_ignore_url?, false) do
        Rss::PageCrawler.stub(:fetch_feed, Object.new) do
          Rss::PageCrawler.stub(:feed_items, [ :item ]) do
            Rss::PageCrawler.stub(:extract_item_attributes, list_attr) do
              Faraday.stub(:get, response) do
                assert_no_difference("Article.count") do
                  Rss::PageCrawler.crawl(@site)
                end
              end
            end
          end
        end
      end
    end
  end
end
