# frozen_string_literal: true

require "test_helper"

class Api::V1::LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "JSON like create without token returns 401" do
    post api_v1_article_like_path(@article, format: :json),
         params: { likeable_type: "Article" },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON like create with valid JWT succeeds" do
    post api_v1_auth_login_path,
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_predicate token, :present?

    post api_v1_article_like_path(@article, format: :json),
         params: { likeable_type: "Article" },
         headers: { "Authorization" => token },
         as: :json

    assert_response :created
    assert @user.reload.likes?(@article)
  end


  test "JSON like create for missing article returns 404 JSON" do
    token = login_token

    post "/api/v1/articles/does-not-exist/like",
         params: { likeable_type: "Article" },
         headers: { "Authorization" => token },
         as: :json

    assert_response :not_found
    assert_equal "not_found", JSON.parse(response.body)["error"]
  end

  # 응답 포맷 분리 고정: 누군가 api/v1에 `format.turbo_stream`을 되돌리면
  # Accept가 turbo_stream인 이 요청이 turbo-stream 본문을 받게 되어 실패한다.
  test "api/v1 answers JSON even when turbo_stream is requested" do
    token = login_token

    post api_v1_article_like_path(@article),
         params: { likeable_type: "Article" },
         headers: { "Authorization" => token },
         as: :turbo_stream

    assert_response :created
    assert_equal "application/json", response.media_type
  end

  private

  def login_token
    post api_v1_auth_login_path,
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    response.headers["Authorization"]
  end
end
