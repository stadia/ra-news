# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

class TwitterServiceTest < ActiveSupport::TestCase
  # Twitter 포스팅/삭제 기능을 mock을 사용하여 테스트

  # MockResponse 헬퍼 Struct
  MockResponse = Struct.new(:status, :body, keyword_init: true)

  setup do
    @article = articles(:ruby_article)
    @article.update(twitter_id: nil) # 포스팅 전 상태로 초기화

    # 태그 연결 설정
    @article.tags << tags(:ruby_tag) unless @article.tags.include?(tags(:ruby_tag))
    @article.tags << tags(:rails_tag) unless @article.tags.include?(tags(:rails_tag))
  end

  # 성공적인 포스팅 테스트
  test "post_to_platform은 성공 시 twitter_id를 저장한다" do
    mock_response = MockResponse.new(status: 200, body: { "data" => { "id" => "1234567890" } })

    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| mock_response }

    service = TwitterService.new

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.success?
      assert_equal "1234567890", result.value!
    end

    @article.reload
    assert_equal "1234567890", @article.twitter_id
  end

  # 이미 포스팅된 기사는 실패해야 함
  test "post_to_platform은 이미 포스팅된 기사의 경우 failure를 반환한다" do
    @article.update(twitter_id: "existing_id")

    service = TwitterService.new

    # platform_client가 호출되지 않아야 함
    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| raise "Should not be called" }

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal :already_posted, result.failure
    end
  end

  # API 에러 시 실패 처리
  test "post_to_platform은 API 에러 시 failure를 반환한다" do
    mock_response = MockResponse.new(status: 403, body: {})

    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| mock_response }

    service = TwitterService.new

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal 403, result.failure
    end
  end

  # 삭제 성공 테스트
  test "delete_from_platform은 성공 시 twitter_id를 nil로 설정한다" do
    @article.update(twitter_id: "1234567890")

    mock_response = MockResponse.new(status: 200, body: {})

    mock_client = Object.new
    mock_client.define_singleton_method(:delete) { |_| mock_response }

    service = TwitterService.new

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :delete)

      assert result.success?
      assert_equal @article.id, result.value!
    end

    @article.reload
    assert_nil @article.twitter_id
  end

  # twitter_id가 없는 기사 삭제 시도
  test "delete_from_platform은 twitter_id가 없으면 failure를 반환한다" do
    @article.update(twitter_id: nil)

    service = TwitterService.new
    mock_client = Object.new
    mock_client.define_singleton_method(:delete) { |_| raise "Should not be called" }

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :delete)

      assert result.failure?
      assert_equal :no_social_id, result.failure
    end
  end

  # Ruby 관련이 아닌 기사는 포스팅하지 않음
  test "should_post_article?은 is_related가 false인 기사를 건너뛴다" do
    @article.update(is_related: false)

    service = TwitterService.new
    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| raise "Should not be called" }

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal :not_suitable, result.failure
    end
  end

  # slug가 없는 기사는 포스팅하지 않음
  test "should_post_article?은 slug가 없는 기사를 건너뛴다" do
    @article.update(slug: nil)

    service = TwitterService.new
    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| raise "Should not be called" }

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal :not_suitable, result.failure
    end
  end

  # title_ko가 없는 기사는 포스팅하지 않음
  test "should_post_article?은 title_ko가 없는 기사를 건너뛴다" do
    @article.update(title_ko: nil)

    service = TwitterService.new
    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| raise "Should not be called" }

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal :not_suitable, result.failure
    end
  end

  # 잘못된 command 처리
  test "call은 알 수 없는 command에 대해 ArgumentError를 발생시킨다" do
    service = TwitterService.new

    assert_raises(ArgumentError) do
      service.call(@article, command: :invalid)
    end
  end

  # 포스트 텍스트 생성 테스트
  test "build_post_text는 280자 이내의 텍스트를 생성한다" do
    service = TwitterService.new

    # private 메서드이므로 send를 사용
    post_text = service.send(:build_post_text, @article)

    # Twitter 제한 280자 확인 (URL 단축 고려)
    assert post_text.length <= 280 + 23, "포스트 텍스트가 너무 깁니다: #{post_text.length}자"
    assert post_text.include?(@article.title_ko)
    assert post_text.include?("ruby-news.kr")
  end

  # 태그가 확인된 것만 사용하는지 테스트
  test "build_post_text는 확인된 태그만 사용한다" do
    # 확인되지 않은 태그 추가
    unconfirmed_tag = tags(:new_feature_tag)
    @article.tags << unconfirmed_tag unless @article.tags.include?(unconfirmed_tag)

    service = TwitterService.new
    post_text = service.send(:build_post_text, @article)

    # 확인된 태그(ruby_tag)는 포함되어야 함
    assert post_text.include?("#ruby"), "확인된 태그가 포함되어야 합니다"
    # 확인되지 않은 태그는 포함되지 않아야 함
    refute_includes post_text, "#new-features", "확인되지 않은 태그는 포함되지 않아야 합니다"
  end

  # 가장 taggings_count가 높은 태그 하나만 사용
  test "build_post_text는 taggings_count가 가장 높은 태그 하나만 사용한다" do
    service = TwitterService.new
    post_text = service.send(:build_post_text, @article)

    # ruby_tag(5)가 rails_tag(3)보다 taggings_count가 높음
    assert post_text.include?("#ruby")
    # 다른 태그는 포함되지 않아야 함 (Twitter는 하나만 사용)
    tag_count = post_text.scan(/#\w+/).count
    assert_equal 1, tag_count, "Twitter 포스트에는 태그가 하나만 있어야 합니다"
  end

  # platform_name 테스트
  test "platform_name은 X.com을 반환한다" do
    service = TwitterService.new
    assert_equal "X.com", service.send(:platform_name)
  end

  # API 500 에러 처리 테스트
  test "post_to_platform은 500 에러 시 failure를 반환한다" do
    mock_response = MockResponse.new(status: 500, body: {})

    mock_client = Object.new
    mock_client.define_singleton_method(:post) { |_| mock_response }

    service = TwitterService.new

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :post)

      assert result.failure?
      assert_equal 500, result.failure
    end
  end

  # 삭제 API 에러 처리 테스트
  test "delete_from_platform은 API 에러 시 failure를 반환한다" do
    @article.update(twitter_id: "1234567890")

    mock_response = MockResponse.new(status: 404, body: {})

    mock_client = Object.new
    mock_client.define_singleton_method(:delete) { |_| mock_response }

    service = TwitterService.new

    service.stub(:platform_client, mock_client) do
      result = service.call(@article, command: :delete)

      assert result.failure?
      assert_equal 404, result.failure
    end
  end
end
