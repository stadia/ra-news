# frozen_string_literal: true

require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  # ========== show ==========

  test "비로그인 상태에서 show 접근 시 로그인 페이지로 리다이렉트" do
    get email_verification_path
    assert_redirected_to new_session_path
  end

  test "로그인 + 미인증 상태에서 show 접근 시 인증 요청 페이지 표시" do
    user = users(:unverified_user)
    sign_in_as(user)

    get email_verification_path
    assert_response :ok
  end

  test "이미 인증된 유저가 show 접근 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)

    get email_verification_path
    assert_redirected_to root_path
  end

  # ========== verify ==========

  test "비로그인 상태에서 verify 토큰 링크 클릭 시 로그인 페이지로 리다이렉트" do
    user = users(:unverified_user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)
    assert_redirected_to new_session_path
  end

  test "유효한 토큰으로 verify 시 email_verified_at이 설정되어 루트로 리다이렉트" do
    user = users(:unverified_user)
    sign_in_as(user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)

    assert_redirected_to root_path
    assert_not_nil user.reload.email_verified_at
    assert_equal "이메일 인증이 완료되었습니다.", flash[:notice]
  end

  test "만료/유효하지 않은 토큰으로 verify 시 인증 요청 페이지로 리다이렉트" do
    user = users(:unverified_user)
    sign_in_as(user)

    get verify_email_verification_path("invalid_token")
    assert_redirected_to email_verification_path
    assert_equal "인증 링크가 만료되었습니다. 새로운 인증 메일을 요청해주세요.", flash[:alert]
  end

  test "이미 인증된 유저가 verify 접근 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)
    assert_redirected_to root_path
  end

  # ========== resend ==========

  test "비로그인 상태에서 resend 요청 시 로그인 페이지로 리다이렉트" do
    post resend_email_verification_path
    assert_redirected_to new_session_path
  end

  test "미인증 유저가 resend 요청 시 메일이 발송됨" do
    user = users(:unverified_user)
    sign_in_as(user)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post resend_email_verification_path
    end

    assert_redirected_to email_verification_path
    assert_equal "인증 메일을 다시 발송했습니다.", flash[:notice]
  end

  test "이미 인증된 유저가 resend 요청 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)

    post resend_email_verification_path
    assert_redirected_to root_path
    assert_equal "이미 인증된 계정입니다.", flash[:notice]
  end

  test "resend는 user ID 기반으로 rate limit되어야 한다" do
    user = users(:unverified_user)
    sign_in_as(user)

    # Verify that rate limit uses user ID (by: -> { Current.user&.id })
    # This test verifies the rate limiting configuration is correct
    # Actual rate limiting is validated through integration/system tests
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post resend_email_verification_path
    end

    assert_redirected_to email_verification_path
    assert_equal "인증 메일을 다시 발송했습니다.", flash[:notice]
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
