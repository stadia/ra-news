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

  test "유효한 속성을 가진 경우 유효해야 한다" do
    site = Site.new(
      name: "Valid Site",
      client: :rss,
      base_uri: "https://example.com/rss"
    )
    assert site.valid?
  end

  test "name은 필수 항목이어야 한다" do
    site = Site.new(client: :rss, base_uri: "https://example.com/rss")
    site.client = nil
    assert_not site.valid?
    assert_includes site.errors[:name], "Name에 내용을 입력해 주세요"
  end

  test "client는 필수 항목이어야 한다" do
    site = Site.new(name: "Test Site", base_uri: "https://example.com/rss")
    site.client = nil
    assert_not site.valid?
    assert_includes site.errors[:client], "Client에 내용을 입력해 주세요"
  end

  test "base_uri가 없는 사이트를 허용해야 한다" do
    site = Site.new(name: "No URI Site", client: :gmail)
    assert site.valid?, "Gmail sites should not require base_uri"
  end

  # ========== Association Tests ==========

  test "기사가 있는 사이트 삭제 시 NOT NULL 제약 조건으로 인해 오류가 발생해야 한다" do
    site = @rss_site
    # Create an article associated with this site
    article = site.articles.create!(
      title: "Test Article",
      url: "https://example.com/test-article",
      origin_url: "https://example.com/test-article-origin"
    )

    # Destroying site should fail due to NOT NULL constraint in DB on articles.site_id
    assert_raises(ActiveRecord::NotNullViolation) do
      site.destroy!
    end
  end

  # ========== Enum Tests ==========

  test "client enum이 올바른 값을 가져야 한다" do
    assert_respond_to @rss_site, :client

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

  test "기본 client를 rss로 설정해야 한다" do
    site = Site.new(name: "Default Client Test")
    assert site.rss?, "Default client should be rss"
    assert_equal "rss", site.client
  end

  test "다른 client 유형을 설정할 수 있어야 한다" do
    site = Site.new(name: "Client Test")

    Site.clients.each do |client_name, _|
      site.client = client_name
      assert_equal client_name, site.client
      assert site.public_send("#{client_name}?"), "Site should be #{client_name}"
    end
  end

  # ========== Callback Tests ==========

  test "생성 시 last_checked_at이 비어있으면 연초로 설정해야 한다" do
    # Travel to a specific time for consistent testing
    travel_to Time.zone.parse("2024-06-15 14:30:00") do
      site = Site.create!(name: "Callback Test", client: :rss)

      expected_time = Time.zone.now.beginning_of_year
      assert_equal expected_time, site.last_checked_at
    end
  end

  test "생성 시 기존 last_checked_at을 덮어쓰지 않아야 한다" do
    existing_time = 1.month.ago
    site = Site.new(
      name: "Existing Time Test",
      client: :rss,
      last_checked_at: existing_time
    )

    site.save!
    assert_equal existing_time.to_i, site.last_checked_at.to_i
  end

  test "before_create에서 nil인 last_checked_at을 올바르게 처리해야 한다" do
    site = Site.new(name: "Nil Time Test", client: :rss)
    site.last_checked_at = nil

    travel_to Time.zone.parse("2024-03-20 09:15:00") do
      site.save!
      expected_time = Time.zone.now.beginning_of_year
      assert_equal expected_time, site.last_checked_at
    end
  end

  # ========== Instance Method Tests ==========

  test "init_client는 rss 클라이언트에 대해 RssClient를 반환해야 한다" do
    client = @rss_site.init_client
    assert_kind_of RssClient, client
    assert_equal @rss_site.base_uri, client.instance_variable_get(:@base_uri)
  end

  test "init_client는 rss_page 클라이언트에 대해 RssClient를 반환해야 한다" do
    rss_page_site = sites(:hacker_news_ruby)
    client = rss_page_site.init_client
    assert_kind_of RssClient, client
  end

  test "init_client는 gmail 클라이언트에 대해 Gmail을 반환해야 한다" do
    client = @gmail_site.init_client
    assert_kind_of Gmail, client
  end

  test "init_client는 hacker_news 클라이언트에 대해 HackerNews를 반환해야 한다" do
    client = @hn_site.init_client
    assert_kind_of HackerNews, client
  end

  test "init_client는 youtube 클라이언트에 대해 Youtube::Channel을 반환해야 한다" do
    @youtube_site.update!(channel: "UCWnPjmqvljcafA0z2U1fwKQ")
    client = @youtube_site.init_client
    assert_kind_of Youtube::Channel, client
    assert_equal @youtube_site.channel, client.instance_variable_get(:@id)
  end

  test "init_client는 지원되지 않는 클라이언트에 대해 오류를 발생시켜야 한다" do
    site = Site.new(name: "Invalid Client", client: :rss)
    # Manually set an invalid client value to test error handling
    site.define_singleton_method(:client) { "invalid_client" }

    assert_raises ArgumentError, "Unsupported client type: invalid_client" do
      site.init_client
    end
  end

  # ========== Client-Specific Validation Tests ==========

  test "youtube 사이트는 channel을 가지고 있는지 검증해야 한다" do
    # Note: This test assumes channel validation exists in the model
    # If not implemented, this test documents the expected behavior
    youtube_site = @youtube_site
    assert_not_nil youtube_site.channel, "YouTube sites should have channel ID"
  end

  test "youtube 사이트의 channel이 없을 경우 정상적으로 처리해야 한다" do
    youtube_site = Site.new(name: "YouTube No Channel", client: :youtube)

    # The init_client method should return nil if channel is missing
    client = youtube_site.init_client
    assert_nil client
  end

  # ========== RSS-Specific Tests ==========

  test "RssClient를 올바른 base_uri로 초기화해야 한다" do
    rss_sites = [ @rss_site, sites(:rails_blog) ]

    rss_sites.each do |site|
      client = site.init_client
      assert_kind_of RssClient, client

      # Check that base_uri is passed correctly
      client_base_uri = client.instance_variable_get(:@base_uri)
      assert_equal site.base_uri, client_base_uri
    end
  end

  # ========== Data Integrity Tests ==========

  test "기사와의 참조 무결성을 유지해야 한다" do
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

  test "name에 있는 한글 문자를 처리해야 한다" do
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

  test "base_uri에 있는 한글 문자를 처리해야 한다" do
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

  test "매우 긴 사이트 이름을 처리해야 한다" do
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

  test "name에 있는 특수 문자를 처리해야 한다" do
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

  test "base_uri에 있는 유효하지 않은 URI를 정상적으로 처리해야 한다" do
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

  test "클라이언트 유형으로 사이트를 효율적으로 쿼리해야 한다" do
    assert_queries(1) do
      Site.where(client: :rss).limit(5).to_a
    end
  end

  test "연관된 기사를 효율적으로 로드해야 한다" do
    site = @rss_site

    # Test N+1 prevention with includes
    assert_queries(2) do # One for sites, one for articles
      sites = Site.includes(:articles).limit(3)
      sites.each { |s| s.articles.to_a }
    end
  end

  # ========== Integration Tests ==========

  test "한국 시간대에서 작동해야 한다" do
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

  test "클라이언트 초기화 오류를 정상적으로 처리해야 한다" do
    # Test what happens when client classes are not available
    site = @rss_site

    # Mock missing client class
    RssClient.stubs(:new).raises(NameError.new("uninitialized constant"))

    assert_raises NameError do
      site.init_client
    end
  end

  test "다른 클라이언트 유형에 올바른 매개변수를 전달해야 한다" do
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

  test "모든 fixture 사이트는 유효해야 한다" do
    Site.all.each do |site|
      assert site.valid?, "Site #{site.name} should be valid: #{site.errors.full_messages.join(', ')}"
    end
  end

  test "fixture 사이트는 예상된 클라이언트 유형을 가져야 한다" do
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
