# frozen_string_literal: true

require "test_helper"

class Api::V1::BoostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @post = posts(:root_post)
    @article = articles(:ruby_article)
  end

  test "JSON boost create without token returns 401" do
    post api_v1_article_boost_path(@article, format: :json),
         params: { boostable_type: "Article" },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON boost create with valid JWT succeeds" do
    post api_v1_auth_login_path,
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_predicate token, :present?

    post api_v1_article_boost_path(@article, format: :json),
         params: { boostable_type: "Article" },
         headers: { "Authorization" => token },
         as: :json

    assert_includes [ 200, 201 ], response.status
    assert @user.reload.boosts?(@article)
  end
end
