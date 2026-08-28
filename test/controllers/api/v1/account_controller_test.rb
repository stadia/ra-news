# frozen_string_literal: true

require "test_helper"

class Api::V1::AccountControllerTest < ActionDispatch::IntegrationTest
  test "account response is not cached" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    get api_v1_account_path, headers: { "Authorization" => token }, as: :json

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
  end
end
