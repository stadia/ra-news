# frozen_string_literal: true

require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 with password reset form" do
    get new_password_path
    assert_response :success
    assert_select "h1", text: /비밀번호를 잊으셨나요/
    assert_select "input[type=email]"
  end

  test "GET edit with valid token returns 200" do
    user = users(:john)
    token = user.password_reset_token
    get edit_password_path(token)
    assert_response :success
    assert_select "input[type=password]"
  end
end
