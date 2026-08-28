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

    assert_includes [ 200, 201 ], response.status
    assert @user.reload.likes?(@article)
  end
end
