# typed: strong
# frozen_string_literal: true

require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 with password reset form" do
    get new_user_password_path

    assert_response :success
    assert_select "input[type=email]"
  end

  test "POST create sends reset instructions" do
    user = users(:john)
    post user_password_path, params: { user: { email: user.email } }

    assert_redirected_to new_user_session_path
  end
end
