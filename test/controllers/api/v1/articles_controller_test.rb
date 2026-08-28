# frozen_string_literal: true

require "test_helper"

class Api::V1::ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "GET index is publicly accessible without token" do
    get api_v1_articles_url

    assert_response :success
    body = JSON.parse(response.body)

    assert_kind_of Array, body["articles"]
    assert_kind_of Hash, body["pagination"]
  end

  test "GET index with valid JWT returns 200" do
    user = users(:john)
    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_predicate token, :present?

    get api_v1_articles_url, headers: { "Authorization" => token }

    assert_response :success
  end

  test "GET others returns JSON list" do
    get others_api_v1_articles_url

    assert_response :success
    body = JSON.parse(response.body)

    assert_kind_of Array, body["articles"]
  end

  test "GET tag filters by keyword" do
    article = articles(:ruby_article)
    article.tag_list.add("ruby")
    article.save!

    get tag_api_v1_articles_url(keyword: "ruby")

    assert_response :success
    body = JSON.parse(response.body)
    slugs = body["articles"].map { |a| a["slug"] }

    assert_includes slugs, article.slug
  end
end
