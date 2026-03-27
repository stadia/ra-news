# frozen_string_literal: true

require "test_helper"

module Articles
  class MetadataPreparationServiceTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :status, :headers)
    Video = Struct.new(:published_at, :title)

    test "서비스는 OperationService를 상속한다" do
      service = MetadataPreparationService.new

      assert_kind_of OperationService, service
    end

    test "트래킹 파라미터를 제거하면서 중복 쿼리 파라미터는 보존한다" do
      article = Article.new(url: "https://example.com/post?tag=ruby&utm_source=x&tag=rails", title: "Existing Title")
      response = Response.new("<html></html>", 200, {})

      Faraday.stub(:get, ->(*) { response }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :success?
        assert_equal "https://example.com/post?tag=ruby&tag=rails", article.url
        assert_equal "example.com", article.host
      end
    end

    test "유튜브 URL에서는 재생 위치 파라미터를 제거하고 is_youtube를 설정한다" do
      article = Article.new(url: "https://youtube.com/watch?v=test123&t=30s&feature=share")
      response = Response.new("", 200, {})
      video = Video.new(1.day.ago, "Video title")

      Faraday.stub(:get, ->(*) { response }) do
        Yt::Video.stub(:new, ->(**) { video }) do
          result = MetadataPreparationService.new.call(article)

          assert_predicate result, :success?
          assert_equal "https://youtube.com/watch?v=test123", article.url
          assert article.is_youtube
          assert_equal "Video title", article.title
        end
      end
    end

    test "경로가 짧은 일반 URL은 discard하고 유튜브 URL은 유지한다" do
      response = Response.new("<html></html>", 200, {})
      article = Article.new(url: "https://example.com", origin_url: "https://example.com", title: "Existing Title")
      youtube_article = Article.new(url: "https://www.youtube.com", origin_url: "https://www.youtube.com")
      video = Video.new(1.day.ago, "YouTube title")

      Faraday.stub(:get, ->(*) { response }) do
        Yt::Video.stub(:new, ->(**) { video }) do
          service = MetadataPreparationService.new
          service.call(article)
          service.call(youtube_article)
        end
      end

      assert_not_nil article.deleted_at
      assert youtube_article.is_youtube
      assert_nil youtube_article.deleted_at
    end

    test "fetch 실패 시 failure를 반환한다" do
      article = Article.new(url: "https://example.com/error-test")

      Faraday.stub(:get, ->(*) { raise Faraday::ConnectionFailed.new("Connection failed") }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :failure?
        assert_equal :fetch_failed, result.failure
      end
    end

    test "YouTube API 오류를 정상적으로 처리해야 한다" do
      article = Article.new(
        url: "https://www.youtube.com/watch?v=invalid_video_id",
        is_youtube: true
      )
      response = Response.new("", 200, {})

      Faraday.stub(:get, ->(*) { response }) do
        Yt::Video.stub(:new, ->(**) { raise Yt::Error.new("boom") }) do
          assert_nothing_raised do
            result = MetadataPreparationService.new.call(article)

            assert_predicate result, :success?
          end
        end
      end
    end

    test "기존 published_at이 있으면 유지한다" do
      existing_time = 2.days.ago
      article = Article.new(
        url: "https://example.com/2024/01/15/post",
        title: "Existing Title",
        published_at: existing_time
      )
      response = Response.new("<html><head><title>Title</title></head><body>Body</body></html>", 200, {})

      Faraday.stub(:get, ->(*) { response }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :success?
        assert_equal existing_time.to_i, article.published_at.to_i
      end
    end

    test "미래 날짜가 추출되면 현재 시각으로 보정한다" do
      future_year = 2.years.from_now.year
      article = Article.new(url: "https://example.com/#{future_year}/01/15/post", title: "Existing Title")
      response = Response.new("<html><head><title>Title</title></head><body>Body</body></html>", 200, {})

      travel_to Time.zone.parse("2026-03-27 12:00:00") do
        Faraday.stub(:get, ->(*) { response }) do
          result = MetadataPreparationService.new.call(article)

          assert_predicate result, :success?
          assert_equal Time.zone.now.to_i, article.published_at.to_i
        end
      end
    end

    test "meta published_time에서 발행일을 추출한다" do
      article = Article.new(url: "https://example.com/post", title: "Existing Title")
      response = Response.new(
        '<html><head><meta property="article:published_time" content="2026-03-20T10:30:00+09:00"></head><body>Body</body></html>',
        200,
        {}
      )

      Faraday.stub(:get, ->(*) { response }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :success?
        assert_equal Time.zone.parse("2026-03-20 10:30:00 +09:00").to_i, article.published_at.to_i
      end
    end

    test "json ld 의 datePublished에서 발행일을 추출한다" do
      article = Article.new(url: "https://example.com/post", title: "Existing Title")
      response = Response.new(
        <<~HTML,
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": "NewsArticle",
                  "datePublished": "2026-03-18T09:15:00+09:00"
                }
              </script>
            </head>
            <body>Body</body>
          </html>
        HTML
        200,
        {}
      )

      Faraday.stub(:get, ->(*) { response }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :success?
        assert_equal Time.zone.parse("2026-03-18 09:15:00 +09:00").to_i, article.published_at.to_i
      end
    end

    test "한글 날짜 텍스트에서 발행일을 추출한다" do
      article = Article.new(url: "https://example.com/post", title: "Existing Title")
      response = Response.new(
        '<html><head><title>Title</title></head><body><div class="published-at">2026년 3월 17일</div></body></html>',
        200,
        {}
      )

      Faraday.stub(:get, ->(*) { response }) do
        result = MetadataPreparationService.new.call(article)

        assert_predicate result, :success?
        assert_equal Date.new(2026, 3, 17), article.published_at.to_date
      end
    end
  end
end
