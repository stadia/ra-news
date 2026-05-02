# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders sign in page" do
    get new_user_session_path

    assert_response :success
  end

  test "GET new redirects to root for already signed in user" do
    user = users(:john)
    sign_in_as(user)

    get new_user_session_path

    assert_redirected_to root_url
  end

  test "POST create signs in user with valid credentials" do
    user = users(:john)

    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }

    assert_redirected_to root_url
  end

  test "POST create fails with invalid credentials" do
    post user_session_path, params: {
      user: { email: "wrong@example.com", password: "wrongpassword" }
    }

    assert_response :unprocessable_entity
  end
end
