# frozen_string_literal: true

# rbs_inline: enabled

require "test_helper"

# SocialMediaService 기본 동작 테스트
class SocialMediaServiceTest < ActiveSupport::TestCase
  # 테스트용 구체 클래스 정의
  class TestSocialMediaService < SocialMediaService
    attr_accessor :mock_client, :post_response, :delete_response

    def platform_name
      "TestPlatform"
    end

    def platform_client
      @mock_client
    end

    def post_to_platform(article)
      return Failure(:already_posted) if article.twitter_id.present?

      response = platform_client.post(build_post_text(article))
      if response.status >= 200 && response.status < 300
        Success(response.body["id"])
      else
        Failure(response.status)
      end
    end

    def delete_from_platform(article)
      return Failure(:no_social_id) unless article.twitter_id.present?

      response = platform_client.delete(article.twitter_id)
      if response.status >= 200 && response.status < 300
        Success(article.id)
      else
        Failure(response.status)
      end
    end

    def build_post_text(article)
      content_data = base_content(article)
      "#{content_data[:title]} - #{content_data[:summary]}"
    end
  end

  setup do
    @article = articles(:ruby_article)
    @service = TestSocialMediaService.new
  end

  # === should_post_article? 테스트 ===

  test "should_post_article? returns Success when article is suitable" do
    # is_related: true, slug 있음, title_ko 있음
    assert @article.is_related
    assert @article.slug.present?
    assert @article.title_ko.present?

    # private 메서드 테스트를 위해 send 사용
    result = @service.send(:should_post_article?, @article)
    assert result.success?
  end

  test "should_post_article? returns Failure when article is not related" do
    @article.is_related = false

    result = @service.send(:should_post_article?, @article)
    assert result.failure?
    assert_equal :not_suitable, result.failure
  end

  test "should_post_article? returns Failure when article has no slug" do
    @article.slug = nil

    result = @service.send(:should_post_article?, @article)
    assert result.failure?
    assert_equal :not_suitable, result.failure
  end

  test "should_post_article? returns Failure when article has no title_ko" do
    @article.title_ko = nil

    result = @service.send(:should_post_article?, @article)
    assert result.failure?
    assert_equal :not_suitable, result.failure
  end

  # === base_content 테스트 ===

  test "base_content returns title_ko when present" do
    result = @service.send(:base_content, @article)

    assert_equal @article.title_ko, result[:title]
  end

  test "base_content falls back to title when title_ko is blank" do
    @article.title_ko = nil

    result = @service.send(:base_content, @article)

    assert_equal @article.title, result[:title]
  end

  test "base_content returns summary from summary_key when present" do
    @article.summary_key = [ "첫 번째 요약", "두 번째 요약" ]

    result = @service.send(:base_content, @article)

    assert_equal "첫 번째 요약", result[:summary]
  end

  test "base_content returns default summary when summary_key is blank" do
    @article.summary_key = nil

    result = @service.send(:base_content, @article)

    assert_equal "새로운 Ruby 관련 글이 올라왔습니다.", result[:summary]
  end

  # === article_link 테스트 ===

  test "article_link generates correct URL" do
    result = @service.send(:article_link, "test-slug")

    assert_equal "https://ruby-news.kr/articles/test-slug", result
  end

  # === call 메서드 테스트 ===

  test "call with unknown command raises ArgumentError" do
    assert_raises(ArgumentError) do
      @service.call(@article, command: :unknown)
    end
  end

  # === 추상 메서드 테스트 (기본 SocialMediaService) ===

  test "post_to_platform raises NotImplementedError in base class" do
    base_service = SocialMediaService.new

    assert_raises(NotImplementedError) do
      base_service.send(:post_to_platform, @article)
    end
  end

  test "delete_from_platform raises NotImplementedError in base class" do
    base_service = SocialMediaService.new

    assert_raises(NotImplementedError) do
      base_service.send(:delete_from_platform, @article)
    end
  end

  test "build_post_text raises NotImplementedError in base class" do
    base_service = SocialMediaService.new

    assert_raises(NotImplementedError) do
      base_service.send(:build_post_text, @article)
    end
  end

  test "platform_name raises NotImplementedError in base class" do
    base_service = SocialMediaService.new

    assert_raises(NotImplementedError) do
      base_service.send(:platform_name)
    end
  end

  test "platform_client raises NotImplementedError in base class" do
    base_service = SocialMediaService.new

    assert_raises(NotImplementedError) do
      base_service.send(:platform_client)
    end
  end
end
