# typed: true
# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    _record, @raw_refresh = RefreshToken.issue(@user)
  end

  test "refresh rotates tokens" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_predicate body["access_token"], :present?
    assert_predicate body["refresh_token"], :present?
    assert_not_equal @raw_refresh, body["refresh_token"]
    assert_equal 15.minutes.to_i, body["expires_in"]
  end

  test "old refresh token is revoked after rotation" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json

    assert_response :success

    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json

    assert_response :unauthorized
  end

  test "invalid refresh token returns 401" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: "garbage" },
         as: :json

    assert_response :unauthorized
    assert_equal "invalid_refresh_token", JSON.parse(response.body)["error"]
  end

  test "missing refresh_token returns 400" do
    post api_v1_auth_refresh_path, params: {}, as: :json

    assert_response :bad_request
  end
end
