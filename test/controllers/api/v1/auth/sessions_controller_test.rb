# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "JSON login returns Authorization header and refresh_token body" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json

    assert_response :success
    assert_match(/^Bearer /, response.headers["Authorization"].to_s)

    body = JSON.parse(response.body)

    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
    assert_predicate body["refresh_token"], :present?
  end

  test "JSON login with bad password returns 401 JSON" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "wrong" } },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON logout revokes user refresh tokens" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    assert_match(/^Bearer /, token.to_s)
    assert_operator user.refresh_tokens.active.count, :>=, 1

    delete api_v1_auth_logout_path,
           headers: { "Authorization" => token },
           as: :json

    assert_response :no_content
    assert_equal 0, user.refresh_tokens.active.count
  end
end
