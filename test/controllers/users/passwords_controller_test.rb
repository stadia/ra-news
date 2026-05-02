# frozen_string_literal: true

require "test_helper"

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET edit renders password edit page with reset token" do
    get edit_user_password_path(reset_password_token: "test-token-123")

    assert_response :success
    assert_includes response.body, "새 비밀번호"
  end
end
