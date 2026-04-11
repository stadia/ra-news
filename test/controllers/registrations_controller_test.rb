# frozen_string_literal: true

require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET new shows signup fields with optional name" do
    get new_user_registration_path

    assert_response :success
    assert_select 'input[name="user[username]"][required]'
    assert_select 'input[name="user[email]"][required]'
    assert_select 'input[name="user[name]"]'
    assert_select 'input[name="user[password]"]'
    assert_select 'input[name="user[password_confirmation]"]'
    assert_select "label", text: "이름 (선택)"
  end

  test "GET edit shows only editable account fields" do
    user = users(:john)
    sign_in_as(user)

    get edit_user_registration_path

    assert_response :success
    assert_select 'input[name="user[name]"]'
    assert_select 'input[name="user[email]"]'
    assert_select 'input[name="user[username]"]', 0
    assert_select "a[href='#{account_password_path}']", text: "비밀번호 변경"
    assert_select "a[href='#{user_profile_path(user)}']", text: "돌아가기"
    assert_select "h2", text: "Slack 채널 구독"
    assert_select "a[href='#{slack_install_path}']", text: "워크스페이스 연결"
  end

  test "PATCH update changes name and email but not username" do
    user = users(:john)
    sign_in_as(user)

    patch user_registration_path, params: {
      user: {
        name: "수정된 이름",
        email: "updated-john@example.com",
        username: "changed_username"
      }
    }

    assert_redirected_to edit_user_registration_path

    user.reload

    assert_equal "수정된 이름", user.name
    assert_equal "john@example.com", user.email
    assert_equal "updated-john@example.com", user.unconfirmed_email
    assert_equal "john", user.username
  end

  test "PATCH update with email change shows reconfirmation notice" do
    user = users(:john)
    sign_in_as(user)

    patch user_registration_path, params: {
      user: { email: "new-john@example.com" }
    }

    assert_redirected_to edit_user_registration_path
    assert_equal I18n.t("devise.registrations.update_needs_confirmation"), flash[:notice]
  end

  test "PATCH update with name only shows updated notice" do
    user = users(:john)
    sign_in_as(user)

    patch user_registration_path, params: {
      user: { name: "새 이름" }
    }

    assert_redirected_to edit_user_registration_path
    assert_equal I18n.t("devise.registrations.updated"), flash[:notice]
  end

  test "GET password shows password form for signed in user" do
    sign_in_as(users(:john))

    get account_password_path

    assert_response :success
    assert_select 'input[name="user[current_password]"]'
    assert_select 'input[name="user[password]"]'
    assert_select 'input[name="user[password_confirmation]"]'
  end
end
