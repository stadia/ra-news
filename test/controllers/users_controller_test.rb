# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "회원가입 성공 시 인증 메일이 발송되어야 한다" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post user_path, params: {
        user: {
          email_address: "newuser@example.com",
          name: "새사용자",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "회원가입 성공 시 이메일 인증 요청 페이지로 리다이렉트되어야 한다" do
    post user_path, params: {
      user: {
        email_address: "newuser2@example.com",
        name: "새사용자둘",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to email_verification_path
  end

  test "회원가입 성공 시 세션이 시작되어야 한다" do
    post user_path, params: {
      user: {
        email_address: "newuser3@example.com",
        name: "새사용자셋",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to email_verification_path
    assert_not_nil cookies[:session_id]
  end

  test "미인증 유저가 프로필 수정 페이지 접근 시 이메일 인증 요청 페이지로 리다이렉트" do
    user = users(:unverified_user)
    post session_path, params: { email_address: user.email_address, password: "password" }

    get edit_users_path
    assert_redirected_to email_verification_path
    assert_equal "이메일 인증이 필요합니다.", flash[:alert]
  end

  test "인증된 유저는 프로필 수정 페이지에 접근 가능" do
    user = users(:john)
    post session_path, params: { email_address: user.email_address, password: "password" }

    get edit_users_path
    assert_response :ok
  end
end
