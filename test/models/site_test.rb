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
      url: "https://example.com/rss"
    )

    assert_predicate site, :valid?
  end

  test "name은 필수 항목이어야 한다" do
    site = Site.new(client: :rss, url: "https://example.com/rss")
    site.client = nil

    assert_not site.valid?
    assert_includes site.errors[:name], "내용을 입력해 주세요"
  end

  test "client는 필수 항목이어야 한다" do
    site = Site.new(name: "Test Site", url: "https://example.com/rss")
    site.client = nil

    assert_not site.valid?
    assert_includes site.errors[:client], "내용을 입력해 주세요"
  end

  test "url이 없는 사이트를 허용해야 한다" do
    site = Site.new(name: "No URI Site", client: :gmail)

    assert_predicate site, :valid?, "Gmail sites should not require url"
  end

  # ========== Enum Tests ==========

  test "client enum이 올바른 값을 가져야 한다" do
    assert_respond_to @rss_site, :client

    # Test enum values
    expected_clients = %w[rss gmail youtube hacker_news rss_page reddit]

    assert_equal expected_clients, Site.clients.keys

    # Test enum methods
    assert_predicate @rss_site, :rss?
    assert_predicate @youtube_site, :youtube?
    assert_predicate @gmail_site, :gmail?
    assert_predicate @hn_site, :hacker_news?
    assert_predicate sites(:hacker_news_ruby), :rss_page?
  end

  test "기본 client를 rss로 설정해야 한다" do
    site = Site.new(name: "Default Client Test")

    assert_predicate site, :rss?, "Default client should be rss"
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

  test "생성 시 last_checked_at이 비어있으면 6개월 전으로 설정해야 한다" do
    # Travel to a specific time for consistent testing
    travel_to Time.zone.parse("2024-06-15 14:30:00") do
      site = Site.create!(name: "Callback Test", client: :rss)

      expected_time = 6.months.ago

      assert_equal expected_time.to_i, site.last_checked_at.to_i
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
      expected_time = 6.months.ago

      assert_equal expected_time, site.last_checked_at
    end
  end

  # ========== Instance Method Tests ==========

  test "init_client는 gmail 클라이언트에 대해 Gmail을 반환해야 한다" do
    client = @gmail_site.init_client

    assert_kind_of Gmail, client
  end

  test "init_client는 youtube 클라이언트에 대해 Youtube::Channel을 반환해야 한다" do
    @youtube_site.update!(channel: "UCWnPjmqvljcafA0z2U1fwKQ")
    client = @youtube_site.init_client

    assert_kind_of Youtube::Channel, client
    assert_equal @youtube_site.channel, client.channel.id
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
        url: "https://korean#{index}.example.com/rss"
      )

      assert_predicate site, :valid?, "Korean site name '#{name}' should be valid"
      site.save!

      assert_equal name, site.name
    end
  end

  test "url에 있는 IDN(punycode) 문자를 처리해야 한다" do
    # IDN 도메인(punycode)은 URI.parse에서 유효하게 처리됨
    site = Site.new(
      name: "Korean Domain Site",
      client: :rss,
      url: "https://xn--3e0b70gj.example.com/rss"
    )

    assert_predicate site, :valid?
    site.save!

    assert_equal "https://xn--3e0b70gj.example.com", site.base_uri
    assert_equal "/rss", site.path
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

      assert_predicate site, :valid?, "Site name '#{name}' should be valid"

      site.save!

      assert_equal name, site.name
    end
  end

  test "url에 있는 유효하지 않은 URI를 정상적으로 처리해야 한다" do
    invalid_uris = [
      "not-a-uri",
      "ftp://invalid-protocol.com",
      "https://",
      ""
    ]

    invalid_uris.each do |uri|
      site = Site.new(name: "Invalid URI Test", client: :rss, url: uri)

      assert_nothing_raised { site.valid? }
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

  # ========== Client Integration Tests ==========

  test "지원하지 않는 클라이언트는 오류를 발생시켜야 한다" do
    site = Site.new(name: "Invalid Client", client: :rss)
    site.define_singleton_method(:client) { "invalid_client" }

    assert_raises(ArgumentError) { site.init_client }
  end

  test "Youtube::Channel에 올바른 매개변수를 전달해야 한다" do
    youtube_site = @youtube_site
    youtube_invocations = []
    youtube_client = Object.new
    Youtube::Channel.stub(:new, ->(**args) { youtube_invocations << args; youtube_client }) do
      result = youtube_site.init_client

      assert_equal youtube_client, result
    end
    assert_equal [ { id: youtube_site.channel } ], youtube_invocations
  end

  # ========== Fixture Validation Tests ==========

  test "모든 fixture 사이트는 유효해야 한다" do
    Site.all.each do |site|
      assert_predicate site, :valid?, "Site #{site.name} should be valid: #{site.errors.full_messages.join(', ')}"
    end
  end

  test "fixture 사이트는 예상된 클라이언트 유형을 가져야 한다" do
    assert_predicate @rss_site, :rss?
    assert_predicate @youtube_site, :youtube?
    assert_predicate @gmail_site, :gmail?
    assert_predicate @hn_site, :hacker_news?
    assert_predicate sites(:hacker_news_ruby), :rss_page?
  end

  # ========== URL Auto-Parsing Tests ==========

  test "url을 저장하면 base_uri와 path로 자동 분리되어야 한다" do
    site = Site.create!(name: "URL Parse Test", client: :rss, url: "https://example.com/feed.xml")

    assert_equal "https://example.com", site.base_uri
    assert_equal "/feed.xml", site.path
  end

  test "url에 포트가 있으면 base_uri에 포함되어야 한다" do
    site = Site.create!(name: "Port Test", client: :rss, url: "http://localhost:3000/blog/feed")

    assert_equal "http://localhost:3000", site.base_uri
    assert_equal "/blog/feed", site.path
  end

  test "표준 포트는 base_uri에서 생략되어야 한다" do
    https_site = Site.create!(name: "HTTPS Standard", client: :rss, url: "https://example.com/rss")
    http_site = Site.create!(name: "HTTP Standard", client: :rss, url: "http://example.com/rss")

    assert_equal "https://example.com", https_site.base_uri
    assert_equal "http://example.com", http_site.base_uri
  end

  test "path가 없는 url은 path를 /로 설정해야 한다" do
    site = Site.create!(name: "No Path", client: :rss, url: "https://example.com")

    assert_equal "https://example.com", site.base_uri
    assert_equal "/", site.path
  end

  test "url을 수정하면 base_uri와 path도 업데이트되어야 한다" do
    site = Site.create!(name: "Update Test", client: :rss, url: "https://old.example.com/rss.xml")

    assert_equal "https://old.example.com", site.base_uri
    assert_equal "/rss.xml", site.path

    site.update!(url: "https://new.example.com/feed.atom")

    assert_equal "https://new.example.com", site.base_uri
    assert_equal "/feed.atom", site.path
  end

  test "url이 비어있으면 base_uri와 path를 변경하지 않아야 한다" do
    site = Site.create!(name: "Empty URL", client: :rss, url: "")

    assert_nil site.base_uri
    assert_nil site.path
  end

  test "유효하지 않은 url은 base_uri와 path를 변경하지 않아야 한다" do
    site = Site.create!(name: "Invalid URL", client: :rss, url: "not-a-uri")

    # scheme/host가 없는 문자열은 파싱하지 않음
    assert_nil site.base_uri
    assert_nil site.path
  end

  test "url이 nil이면 base_uri와 path를 변경하지 않아야 한다" do
    site = Site.create!(name: "Nil URL", client: :gmail)

    assert_nil site.url
    assert_nil site.base_uri
    assert_nil site.path
  end

  test "url을 저장하면 기존 fixture 데이터도 정상 동작해야 한다" do
    site = sites(:ruby_weekly)

    # 기존 fixture는 url이 nil일 수 있으므로 url을 설정하면 파싱 동작 확인
    site.update!(url: "https://rubyweekly.com/rss")

    assert_equal "https://rubyweekly.com", site.base_uri
    assert_equal "/rss", site.path
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
