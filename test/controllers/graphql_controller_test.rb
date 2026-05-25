# frozen_string_literal: true

require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  ARTICLE_FEED_QUERY = <<~GRAPHQL
    query ArticleFeed($kind: ArticleFeedKind!, $search: String, $keyword: String, $page: String, $limit: Int) {
      articleFeed(kind: $kind, search: $search, keyword: $keyword, page: $page, limit: $limit) {
        articles {
          slug
          title
          titleKo
          url
          host
          isRelated
          likersCount
          postsCount
          summaryKey
          tags
          liked
          publishedAt
          createdAt
          updatedAt
        }
        pagination {
          page
          nextPage
          limit
        }
      }
    }
  GRAPHQL

  test "public related feed returns articles and pagination" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "RELATED" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["errors"]
    assert_kind_of Array, body.dig("data", "articleFeed", "articles")
    assert_kind_of Hash, body.dig("data", "articleFeed", "pagination")
    assert_equal 15, body.dig("data", "articleFeed", "pagination", "limit")
  end

  test "public others feed returns articles" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "OTHERS" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["errors"]
    assert_kind_of Array, body.dig("data", "articleFeed", "articles")
  end

  test "public tagged feed filters by keyword" do
    article = articles(:ruby_article)
    make_visible_related_article(article)
    article.tag_list.add("ruby")
    article.save!

    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "TAGGED", keyword: "ruby" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    slugs = body.dig("data", "articleFeed", "articles").map { |item| item["slug"] }

    assert_nil body["errors"]
    assert_includes slugs, article.slug
  end

  test "authenticated related feed marks liked articles" do
    user = users(:john)
    article = articles(:ruby_article)
    make_visible_related_article(article)
    user.like!(article)
    token = jwt_for(user)

    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "RELATED" } },
         headers: { "Authorization" => token },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    liked_article = body.dig("data", "articleFeed", "articles").find { |item| item["slug"] == article.slug }

    assert_nil body["errors"]
    assert_not_nil liked_article
    assert liked_article["liked"]
  end

  test "tagged feed requires keyword" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "TAGGED" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["data"]
    assert_match "keyword is required for tagged article feed", body["errors"].first["message"]
  end

  private
    def make_visible_related_article(article)
      article.update!(
        deleted_at: nil,
        is_related: true,
        title_ko: article.title_ko.presence || "루비 기사",
        slug: article.slug.presence || "ruby-article",
        published_at: article.published_at || Time.current
      )
    end

    def jwt_for(user)
      post user_session_path,
           params: { user: { email: user.email, password: "password" } },
           as: :json

      response.headers.fetch("Authorization")
    end
end
