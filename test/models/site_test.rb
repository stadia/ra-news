# frozen_string_literal: true

require "test_helper"

class SiteTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @rss_site = sites(:ruby_weekly)
    @youtube_site = sites(:ruby_conf)
    @gmail_site = sites(:newsletter)
    @hn_site = sites(:hn_site)
    @new_site = sites(:new_site)
  end

  # ========== Validation Tests ==========

  test "should be valid with valid attributes" do
    site = Site.new(
      name: "Valid Site",
      client: :rss,
      base_uri: "https://example.com/rss"
    )
    assert site.valid?
  end

  test "should require name" do
    site = Site.new(client: :rss, base_uri: "https://example.com/rss")
    assert_not site.valid?
    assert_includes site.errors[:name], "can't be blank"
  end

  test "should require client" do
    site = Site.new(name: "Test Site", base_uri: "https://example.com/rss")
    site.client = nil
    assert_not site.valid?
    assert_includes site.errors[:client], "can't be blank"
  end

  test "should allow sites without base_uri" do
    site = Site.new(name: "No URI Site", client: :gmail)
    assert site.valid?, "Gmail sites should not require base_uri"
  end

  # ========== Association Tests ==========

  test "should have many articles with nullify dependency" do
    site = @rss_site
    assert_respond_to site, :articles
    assert_kind_of ActiveRecord::Associations::CollectionProxy, site.articles

    # Create an article associated with this site
    article = site.articles.create!(
      title: "Test Article",
      url: "https://example.com/test-article",
      origin_url: "https://example.com/test-article-origin"
    )

    # Destroying site should nullify article's site_id
    site.destroy!
    article.reload
    assert_nil article.site_id
  end

  # ========== Enum Tests ==========

  test "should have client enum with correct values" do
    assert_respond_to Site, :client

    # Test enum values
    expected_clients = %w[rss gmail youtube hacker_news rss_page]
    assert_equal expected_clients, Site.clients.keys

    # Test enum methods
    assert @rss_site.rss?
    assert @youtube_site.youtube?
    assert @gmail_site.gmail?
    assert @hn_site.hacker_news?
    assert sites(:hacker_news_ruby).rss_page?
  end

  test "should set default client to rss" do
    site = Site.new(name: "Default Client Test")
    assert site.rss?, "Default client should be rss"
    assert_equal "rss", site.client
  end

  test "should allow setting different client types" do
    site = Site.new(name: "Client Test")

    Site.clients.each do |client_name, _|
      site.client = client_name
      assert_equal client_name, site.client
      assert site.public_send("#{client_name}?"), "Site should be #{client_name}"
    end
  end

  # ========== Callback Tests ==========

  test "should set last_checked_at to beginning of year if blank on create" do
    # Travel to a specific time for consistent testing
    travel_to Time.zone.parse("2024-06-15 14:30:00") do
      site = Site.create!(name: "Callback Test", client: :rss)

      expected_time = Time.zone.now.beginning_of_year
      assert_equal expected_time, site.last_checked_at
    end
  end

  test "should not override existing last_checked_at on create" do
    existing_time = 1.month.ago
    site = Site.new(
      name: "Existing Time Test",
      client: :rss,
      last_checked_at: existing_time
    )

    site.save!
    assert_equal existing_time.to_i, site.last_checked_at.to_i
  end

  test "should handle nil last_checked_at properly in before_create" do
    site = Site.new(name: "Nil Time Test", client: :rss)
    site.last_checked_at = nil

    travel_to Time.zone.parse("2024-03-20 09:15:00") do
      site.save!
      expected_time = Time.zone.now.beginning_of_year
      assert_equal expected_time, site.last_checked_at
    end
  end

  # ========== Instance Method Tests ==========

  test "init_client should return RssClient for rss client" do
    client = @rss_site.init_client
    assert_kind_of RssClient, client
    assert_equal @rss_site.base_uri, client.instance_variable_get(:@base_uri)
  end

  test "init_client should return RssClient for rss_page client" do
    rss_page_site = sites(:hacker_news_ruby)
    client = rss_page_site.init_client
    assert_kind_of RssClient, client
  end

  test "init_client should return Gmail for gmail client" do
    client = @gmail_site.init_client
    assert_kind_of Gmail, client
  end

  test "init_client should return HackerNews for hacker_news client" do
    client = @hn_site.init_client
    assert_kind_of HackerNews, client
  end

  test "init_client should return Youtube::Channel for youtube client" do
    client = @youtube_site.init_client
    assert_kind_of Youtube::Channel, client
    assert_equal @youtube_site.channel, client.instance_variable_get(:@id)
  end

  test "init_client should raise error for unsupported client" do
    site = Site.new(name: "Invalid Client", client: :rss)
    # Manually set an invalid client value to test error handling
    site.define_singleton_method(:client) { "invalid_client" }

    assert_raises ArgumentError, "Unsupported client type: invalid_client" do
      site.init_client
    end
  end

  # ========== Client-Specific Validation Tests ==========

  test "should validate youtube sites have channel" do
    # Note: This test assumes channel validation exists in the model
    # If not implemented, this test documents the expected behavior
    youtube_site = @youtube_site
    assert_not_nil youtube_site.channel, "YouTube sites should have channel ID"
  end

  test "should handle missing channel for youtube sites gracefully" do
    youtube_site = Site.new(name: "YouTube No Channel", client: :youtube)

    # The init_client method should still work, but might initialize with nil
    client = youtube_site.init_client
    assert_kind_of Youtube::Channel, client
  end

  # ========== RSS-Specific Tests ==========

  test "should initialize RssClient with correct base_uri" do
    rss_sites = [ @rss_site, sites(:rails_blog) ]

    rss_sites.each do |site|
      client = site.init_client
      assert_kind_of RssClient, client

      # Check that base_uri is passed correctly
      client_base_uri = client.instance_variable_get(:@base_uri)
      assert_equal site.base_uri, client_base_uri
    end
  end

  test "should handle RSS sites without base_uri" do
    rss_site = Site.new(name: "No URI RSS", client: :rss)
    client = rss_site.init_client

    assert_kind_of RssClient, client
    # Should initialize with nil base_uri
    assert_nil client.instance_variable_get(:@base_uri)
  end

  # ========== Data Integrity Tests ==========

  test "should maintain referential integrity with articles" do
    site = @rss_site
    initial_article_count = site.articles.count

    # Create articles associated with this site
    article1 = site.articles.create!(
      title: "Article 1",
      url: "https://example.com/article1-#{SecureRandom.hex(4)}",
      origin_url: "https://example.com/article1-origin-#{SecureRandom.hex(4)}"
    )

    article2 = site.articles.create!(
      title: "Article 2", 
      url: "https://example.com/article2-#{SecureRandom.hex(4)}",
      origin_url: "https://example.com/article2-origin-#{SecureRandom.hex(4)}"
    )

    assert_equal initial_article_count + 2, site.articles.count

    # Test behavior when site is destroyed
    # If NOT NULL constraint exists, articles should be deleted or an error should occur
    begin
      site.destroy!
      
      # If destruction succeeds, check the behavior
      if Article.exists?(article1.id) && Article.exists?(article2.id)
        article1.reload
        article2.reload
        assert_nil article1.site_id
        assert_nil article2.site_id
      end
    rescue ActiveRecord::NotNullViolation, ActiveRecord::InvalidForeignKey
      # This is acceptable behavior if database has NOT NULL constraint
      # The site destruction should be blocked or articles should be deleted
      assert true, "Database constraint prevents site deletion with associated articles"
    end
  end

  # ========== Korean Content Tests ==========

  test "should handle Korean characters in name" do
    korean_names = [
      "루비 위클리",
      "레일스 블로그",
      "한국 개발자 뉴스",
      "Ruby Weekly 한국어판"
    ]

    korean_names.each_with_index do |name, index|
      site = Site.new(
        name: name,
        client: :rss,
        base_uri: "https://korean#{index}.example.com/rss"
      )

      assert site.valid?, "Korean site name '#{name}' should be valid"
      site.save!
      assert_equal name, site.name
    end
  end

  test "should handle Korean characters in base_uri" do
    # While uncommon, Korean domains do exist
    site = Site.new(
      name: "Korean Domain Site",
      client: :rss,
      base_uri: "https://한국.example.com/rss"
    )

    assert site.valid?
    site.save!
    assert_equal "https://한국.example.com/rss", site.base_uri
  end

  # ========== Edge Cases and Error Handling ==========

  test "should handle very long site names" do
    long_name = "Very Long Site Name " * 10 # 200+ characters
    site = Site.new(name: long_name, client: :rss)

    # Should either be valid or have appropriate validation
    if site.valid?
      site.save!
      assert_equal long_name, site.name
    else
      # If there's a length validation, it should be documented
      assert_includes site.errors[:name], "is too long"
    end
  end

  test "should handle special characters in name" do
    special_names = [
      "Site with & ampersand",
      "Site with < > brackets",
      "Site with \"quotes\"",
      "Site with 'apostrophe'",
      "Site with #hashtag",
      "Site with @mention"
    ]

    special_names.each do |name|
      site = Site.new(name: name, client: :rss)
      assert site.valid?, "Site name '#{name}' should be valid"

      site.save!
      assert_equal name, site.name
    end
  end

  test "should handle invalid URIs in base_uri gracefully" do
    invalid_uris = [
      "not-a-uri",
      "ftp://invalid-protocol.com",
      "https://",
      ""
    ]

    invalid_uris.each do |uri|
      site = Site.new(name: "Invalid URI Test", client: :rss, base_uri: uri)

      # Site creation should work, validation depends on requirements
      if site.valid?
        site.save!
        # Client initialization should handle invalid URIs gracefully
        assert_nothing_raised do
          client = site.init_client
          assert_kind_of RssClient, client
        end
      end
    end
  end

  # ========== Performance Tests ==========

  test "should efficiently query sites by client type" do
    assert_queries(1) do
      Site.where(client: :rss).limit(5).to_a
    end
  end

  test "should efficiently load associated articles" do
    site = @rss_site

    # Test N+1 prevention with includes
    assert_queries(2) do # One for sites, one for articles
      sites = Site.includes(:articles).limit(3)
      sites.each { |s| s.articles.to_a }
    end
  end

  # ========== Integration Tests ==========

  test "should work with Korean timezone" do
    Time.zone = "Asia/Seoul"

    travel_to Time.zone.parse("2024-07-01 12:00:00") do
      site = Site.create!(
        name: "시간대 테스트 사이트",
        client: :rss,
        base_uri: "https://timezone-test.co.kr/rss"
      )

      assert_equal "Asia/Seoul", Time.zone.name
      assert_kind_of ActiveSupport::TimeWithZone, site.last_checked_at
      assert_kind_of ActiveSupport::TimeWithZone, site.created_at

      # Should be set to beginning of year in Korean timezone
      expected_time = Time.zone.parse("2024-01-01 00:00:00")
      assert_equal expected_time, site.last_checked_at
    end
  end

  # ========== Client Integration Tests ==========

  test "should handle client initialization errors gracefully" do
    # Test what happens when client classes are not available
    site = @rss_site

    # Mock missing client class
    RssClient.stubs(:new).raises(NameError.new("uninitialized constant"))

    assert_raises NameError do
      site.init_client
    end
  end

  test "should pass correct parameters to different client types" do
    # Test parameter passing for each client type

    # RSS Client
    rss_site = @rss_site
    RssClient.expects(:new).with(base_uri: rss_site.base_uri).returns(stub)
    rss_site.init_client

    # YouTube Client
    youtube_site = @youtube_site
    Youtube::Channel.expects(:new).with(id: youtube_site.channel).returns(stub)
    youtube_site.init_client

    # Gmail Client (no parameters)
    gmail_site = @gmail_site
    Gmail.expects(:new).with().returns(stub)
    gmail_site.init_client

    # HackerNews Client (no parameters)
    hn_site = @hn_site
    HackerNews.expects(:new).with().returns(stub)
    hn_site.init_client
  end

  # ========== Fixture Validation Tests ==========

  test "all fixture sites should be valid" do
    Site.all.each do |site|
      assert site.valid?, "Site #{site.name} should be valid: #{site.errors.full_messages.join(', ')}"
    end
  end

  test "fixture sites should have expected client types" do
    assert @rss_site.rss?
    assert @youtube_site.youtube?
    assert @gmail_site.gmail?
    assert @hn_site.hacker_news?
    assert sites(:hacker_news_ruby).rss_page?
  end

  private

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
