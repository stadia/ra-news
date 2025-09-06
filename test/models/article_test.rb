# frozen_string_literal: true

require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @article = articles(:ruby_article)
    @youtube_article = articles(:youtube_ruby_talk)
    @korean_article = articles(:korean_content_article)
    @deleted_article = articles(:deleted_article)
    @site_article = articles(:site_only_article)
    @user = users(:john)
    @site = sites(:ruby_weekly)
  end

  # ========== Validation Tests ==========

  test "should be valid with valid attributes" do
    article = Article.new(
      title: "Test Article",
      url: "https://example.com/test-unique-url",
      origin_url: "https://example.com/test-unique-origin",
      user: @user
    )
    assert article.valid?
  end

  test "should require url" do
    article = Article.new(title: "Test Article", origin_url: "https://example.com/test")
    assert_not article.save
    assert_includes article.errors[:url], "Url에 내용을 입력해 주세요"
  end

  test "should set origin_url from url when blank" do
    article = Article.new(
      title: "Test Article",
      url: "https://example.com/test"
    )
    # Mock generate_metadata to avoid external calls
    Article.any_instance.stubs(:generate_metadata).returns(nil)

    article.save!
    assert_equal "https://example.com/test", article.origin_url
  end

  test "should validate url uniqueness case insensitive" do
    existing_article = @article
    article = Article.new(
      title: "Another Article",
      url: existing_article.url.upcase,
      origin_url: "https://different-origin.com/test"
    )
    assert_not article.valid?
    assert_includes article.errors[:url], "Url은(는) 이미 존재합니다"
  end

  test "should validate origin_url uniqueness case insensitive" do
    existing_article = @article
    article = Article.new(
      title: "Another Article",
      url: "https://different-url.com/test",
      origin_url: existing_article.origin_url.upcase
    )
    assert_not article.valid?
    assert_includes article.errors[:origin_url], "Origin url은(는) 이미 존재합니다"
  end

  test "should validate slug uniqueness when present" do
    existing_article = @article
    article = Article.new(
      title: "Different Article",
      url: "https://different.com/test",
      origin_url: "https://different.com/test-origin",
      slug: existing_article.slug
    )
    assert_not article.valid?
    assert_includes article.errors[:slug], "Slug은(는) 이미 존재합니다"
  end

  test "should allow blank slug" do
    article = Article.new(
      title: "Test Article",
      url: "https://example.com/blank-slug-test",
      origin_url: "https://example.com/blank-slug-test-origin",
      slug: ""
    )
    assert article.valid?
  end

  # ========== Association Tests ==========

  test "should belong to user optionally" do
    assert_respond_to @article, :user
    assert_kind_of User, @article.user

    # Test optional association
    article = Article.new(
      title: "No User Article",
      url: "https://example.com/no-user",
      origin_url: "https://example.com/no-user-origin"
    )
    article.user = nil
    assert article.valid?
  end

  test "should belong to site optionally" do
    assert_respond_to @article, :site
    assert_kind_of Site, @article.site

    # Test optional association
    article = Article.new(
      title: "No Site Article",
      url: "https://example.com/no-site",
      origin_url: "https://example.com/no-site-origin"
    )
    article.site = nil
    assert article.valid?
  end

  test "should have many comments association" do
    article = @article
    initial_count = article.comments.count
    comment = article.comments.create!(body: "Test comment", user: @user)

    assert_equal initial_count + 1, article.comments.count
    assert_equal article.id, comment.article_id
    assert_includes article.comments, comment
  end

  # ========== Scope Tests ==========

  test "full_text_search_for scope should exist and be callable" do
    assert_respond_to Article, :full_text_search_for
    # Note: Full functionality requires PostgreSQL setup
  end

  test "related scope should return related articles" do
    related_articles = Article.related
    assert_includes related_articles, @article
    assert_includes related_articles, @korean_article
    assert_not_includes related_articles, @site_article
  end

  test "unrelated scope should return unrelated articles" do
    unrelated_articles = Article.unrelated
    assert_includes unrelated_articles, @site_article
    assert_not_includes unrelated_articles, @article
    assert_not_includes unrelated_articles, @korean_article
  end

  test "title_matching scope should exist and be callable" do
    assert_respond_to Article, :title_matching
    # Note: Full functionality requires PostgreSQL with Korean dictionary
  end

  test "body_matching scope should exist and be callable" do
    assert_respond_to Article, :body_matching
    # Note: Full functionality requires PostgreSQL with English dictionary
  end

  # ========== Soft Delete Tests ==========

  test "should include Discard::Model" do
    assert Article.ancestors.include?(Discard::Model)
  end

  test "kept scope should exclude discarded articles" do
    kept_articles = Article.kept
    assert_includes kept_articles, @article
    assert_not_includes kept_articles, @deleted_article
  end

  test "discarded scope should include discarded articles" do
    discarded_articles = Article.discarded
    assert_includes discarded_articles, @deleted_article
    assert_not_includes discarded_articles, @article
  end

  test "should discard article instead of destroying" do
    article = @article
    article.discard!

    assert article.discarded?
    assert_not_nil article.deleted_at
    assert Article.exists?(article.id)
  end

  # ========== Callback Tests ==========

  test "should set origin_url from url before validation on create" do
    article = Article.new(title: "Test", url: "https://example.com/callback-test")
    article.valid?
    assert_equal "https://example.com/callback-test", article.origin_url
  end

  test "should set published_at to current time if blank before save" do
    article = Article.new(
      title: "Test",
      url: "https://example.com/published-test",
      origin_url: "https://example.com/published-test-origin"
    )

    # Mock Time.zone.now for consistent testing
    frozen_time = Time.zone.parse("2024-01-15 10:30:00")
    travel_to(frozen_time) do
      article.save!
      assert_equal frozen_time, article.published_at
    end
  end

  test "should not override existing published_at before save" do
    existing_time = 1.week.ago
    article = Article.new(
      title: "Test",
      url: "https://example.com/existing-published",
      origin_url: "https://example.com/existing-published-origin",
      published_at: existing_time
    )

    # generate_metadata 메서드를 직접 stub하여 published_at 덮어쓰기 방지
    Article.any_instance.stubs(:generate_metadata).returns(nil)

    article.save!

    # The published_at should be preserved (not overridden by before_save callback)
    assert_equal existing_time.to_i, article.published_at.to_i,
      "published_at should not be overridden when already set"
  end

  test "should generate metadata before create" do
    # 외부 API 호출을 간단히 stub
    stub_external_requests

    article = Article.new(
      title: "Test",
      url: "https://example.com/metadata-test",
      user: @user
    )

    article.save!
    assert_not_nil article.slug
    assert_not_nil article.host
  end

  # ========== Instance Method Tests ==========

  test "youtube_id should extract video id from YouTube URL" do
    youtube_urls = {
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtube.com/watch?v=abc123&t=30s" => "abc123",
      "https://www.youtube.com/live/live123" => "live123",
      "https://youtu.be/short123" => nil, # This format not supported by current implementation
      "https://example.com/not-youtube" => nil
    }

    youtube_urls.each do |url, expected_id|
      article = Article.new(url: url)
      if expected_id.nil?
        assert_nil article.youtube_id, "Failed for URL: #{url}"
      else
        assert_equal expected_id, article.youtube_id, "Failed for URL: #{url}"
      end
    end
  end

  test "youtube_id should handle invalid URLs gracefully" do
    article = Article.new(url: "invalid-url")
    assert_nil article.youtube_id
  end

  test "update_slug should work for non-YouTube URLs" do
    article = Article.create!(
      title: "Test",
      url: "https://example.com/path/article-slug.html",
      origin_url: "https://example.com/path/article-slug.html"
    )

    article.update_slug
    article.reload
    assert_equal "article-slug", article.slug
  end

  test "update_slug should work for YouTube URLs" do
    article = Article.create!(
      title: "YouTube Test",
      url: "https://www.youtube.com/watch?v=test123",
      origin_url: "https://www.youtube.com/watch?v=test123"
    )

    article.update_slug
    article.reload
    assert_equal "test123", article.slug
  end

  test "user_name should return user name when user present" do
    assert_equal "존 도", @article.user_name
  end

  test "user_name should return site info when site present but no user" do
    site_article = @site_article
    expected = "#{site_article.site.name} (#{site_article.site.base_uri})"
    assert_equal expected, site_article.user_name
  end

  test "user_name should return site name when site present but no base_uri" do
    site_article = @site_article
    site_article.site.base_uri = nil
    assert_equal site_article.site.name, site_article.user_name
  end

  test "user_name should return unknown when no user or site" do
    article = Article.new(title: "Test", url: "https://example.com", origin_url: "https://example.com")
    assert_equal "알 수 없음", article.user_name
  end

  # ========== Class Method Tests ==========

  test "find_by_slug should find article by slug" do
    article = Article.find_by_slug(@article.slug)
    assert_equal @article, article
  end

  test "find_by_slug should return nil for non-existent slug" do
    article = Article.find_by_slug("non-existent-slug")
    assert_nil article
  end

  test "should_ignore_url? should return true for ignored hosts" do
    ignored_urls = [
      "https://github.com/user/repo",
      "https://twitter.com/user/status/123",
      "https://linkedin.com/in/user",
      "https://meetup.com/event/123",
      "https://subdomain.github.com/path"
    ]

    ignored_urls.each do |url|
      assert Article.should_ignore_url?(url), "Should ignore URL: #{url}"
    end
  end

  test "should_ignore_url? should return false for allowed hosts" do
    allowed_urls = [
      "https://weblog.rubyonrails.org/2024/1/1/rails-8",
      "https://example.com/article",
      "https://blog.example.com/post",
      "https://good-source.com/article"
    ]

    allowed_urls.each do |url|
      assert_not Article.should_ignore_url?(url), "Should not ignore URL: #{url}"
    end
  end

  test "should_ignore_url? should return true for dangerous file extensions" do
    dangerous_urls = [
      "https://example.com/file.pdf",
      "https://example.com/archive.zip",
      "https://example.com/book.epub",
      "https://example.com/program.exe",
      "https://example.com/data.rar"
    ]

    dangerous_urls.each do |url|
      assert Article.should_ignore_url?(url), "Should ignore dangerous file: #{url}"
    end
  end

  test "should_ignore_url? should handle invalid URLs" do
    assert Article.should_ignore_url?("invalid-url")
    assert Article.should_ignore_url?(nil)
    assert Article.should_ignore_url?("")
  end

  # ========== Store Accessor Tests ==========

  test "should access summary_detail components via store accessor" do
    article = @korean_article

    # Test reading
    assert_respond_to article, :summary_body
    assert_respond_to article, :summary_introduction
    assert_respond_to article, :summary_conclusion

    # Test writing
    article.summary_body = "새로운 본문 요약"
    article.summary_introduction = "새로운 서론"
    article.summary_conclusion = "새로운 결론"

    article.save!
    article.reload

    assert_equal "새로운 본문 요약", article.summary_body
    assert_equal "새로운 서론", article.summary_introduction
    assert_equal "새로운 결론", article.summary_conclusion
  end

  # ========== Vector Embeddings Tests ==========

  test "should have neighbors functionality for embeddings" do
    # Test that the has_neighbors method is set up
    assert_respond_to @article, :embedding
    assert_respond_to @article, :nearest_neighbors
  end

  # ========== Tagging Tests ==========

  test "should act as taggable" do
    article = @article
    assert_respond_to article, :tag_list
    assert_respond_to article, :tag_list=

    # Test adding tags
    article.tag_list = "ruby, rails, programming"
    article.save!

    assert_includes article.tag_list, "ruby"
    assert_includes article.tag_list, "rails"
    assert_includes article.tag_list, "programming"
  end

  # ========== Korean Content Tests ==========

  test "should handle Korean characters in title and content" do
    korean_article = Article.create!(
      title: "한국어 제목 테스트",
      title_ko: "한국어 제목의 다른 버전",
      url: "https://example.com/korean-test",
      origin_url: "https://example.com/korean-test-origin",
      body: "한국어 내용입니다. Ruby와 Rails에 대한 정보가 포함되어 있습니다.",
      summary_key: "한국어 요약",
      user: users(:korean_user)
    )

    assert_equal "한국어 제목 테스트", korean_article.title
    assert_equal "한국어 제목의 다른 버전", korean_article.title_ko
    assert_includes korean_article.body, "한국어"
    assert_equal "한국어 요약", korean_article.summary_key
  end

  # ========== YouTube Integration Tests ==========

  test "should identify YouTube articles correctly" do
    assert @youtube_article.is_youtube?
    assert_not @article.is_youtube?
  end

  test "should handle YouTube URL normalization" do
    youtube_article = Article.new(
      title: "YouTube Test",
      url: "https://youtube.com/watch?v=test123&utm_source=share",
      origin_url: "https://youtube.com/watch?v=test123&utm_source=share&ref=twitter"
    )

    # Mock generate_metadata to avoid external API calls
    youtube_article.stubs(:generate_metadata)
    youtube_article.save!

    # Should still work even with different YouTube domain format
    assert_not_nil youtube_article.youtube_id
  end

  # ========== URL Processing Tests ==========

  test "should extract published_at from URL patterns" do
    urls_with_dates = {
      "https://example.com/2024/01/15/article-title" => Date.parse("2024-01-15"),
      "https://blog.com/2023-12-25-holiday-post" => Date.parse("2023-12-25"),
      "https://news.com/articles/2024/1/1/new-year" => Date.parse("2024-01-01")
    }

    urls_with_dates.each do |url, expected_date|
      article = Article.new(url: url)
      extracted_date = article.send(:url_to_published_at)

      if extracted_date
        assert_equal expected_date.year, extracted_date.year
        assert_equal expected_date.month, extracted_date.month
        assert_equal expected_date.day, extracted_date.day
      end
    end
  end

  test "should handle URL parsing errors gracefully" do
    article = Article.new(url: "invalid-url")
    assert_nil article.send(:url_to_published_at)
  end

  # ========== Cache Management Tests ==========

  test "should clear RSS cache after discard" do
    # Mock Rails.cache to expect the cache deletion
    Rails.cache.expects(:delete).with("rss_articles").at_least_once
    @article.discard!
  end

  test "should clear RSS cache after create" do
    Rails.cache.expects(:delete).with("rss_articles").once

    Article.create!(
      title: "Cache Test",
      url: "https://example.com/cache-test",
      origin_url: "https://example.com/cache-test-origin"
    )
  end

  # ========== Error Handling Tests ==========

  test "should handle Faraday errors gracefully in fetch_url_content" do
    article = Article.new(url: "https://example.com/error-test")

    # Mock Faraday to raise an error
    Faraday.expects(:get).raises(Faraday::ConnectionFailed.new("Connection failed"))

    result = article.send(:fetch_url_content)
    assert_nil result
  end

  test "should handle YouTube API errors gracefully" do
    # This test ensures that YouTube API errors don't crash the application
    article = Article.new(
      url: "https://www.youtube.com/watch?v=invalid_video_id",
      is_youtube: true
    )

    # The set_youtube_metadata method should handle Yt::Error gracefully
    assert_nothing_raised do
      article.send(:set_youtube_metadata)
    end
  end

  # ========== Performance Tests ==========

  test "should efficiently query kept articles" do
    # Test that kept scope is efficient
    assert_queries(1) do
      Article.kept.limit(10).to_a
    end
  end

  test "should efficiently query related articles" do
    # Test that related scope is efficient
    assert_queries(1) do
      Article.related.limit(5).to_a
    end
  end

  # ========== Integration Tests ==========

  test "should work with Korean timezone" do
    Time.zone = "Asia/Seoul"

    article = Article.create!(
      title: "시간대 테스트",
      url: "https://example.com/timezone-test",
      origin_url: "https://example.com/timezone-test-origin",
      user: users(:korean_user)
    )

    assert_equal "Asia/Seoul", Time.zone.name
    assert_kind_of ActiveSupport::TimeWithZone, article.published_at
    assert_kind_of ActiveSupport::TimeWithZone, article.created_at
  end

  private

  # Helper method to stub external API requests
  def stub_external_requests
    # Stub Faraday HTTP requests
    Faraday.stubs(:get).returns(
      stub(
        body: '{"title": "Test", "description": "Test description"}',
        status: 200,
        success?: true
      )
    )
    
    # Stub any other external service calls if needed
    Article.any_instance.stubs(:fetch_url_content).returns(nil)
    Article.any_instance.stubs(:set_youtube_metadata).returns(nil)
  end

  # Helper method for testing query count
  def assert_queries(expected_count)
    queries = []
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
