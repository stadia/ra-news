# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @user = users(:john)
  end

  # 기존 시스템 테스트는 전부 login_as(Warden)로 UI 로그인을 우회한다.
  # 이 테스트는 실제 new_user_session 폼 제출 경로를 직접 검증해 공백을 보완한다.
  test "사용자가 로그인 폼을 제출하면 로그인에 성공한다" do
    visit new_user_session_path

    # form_with(scope: :user)의 email_field/password_field 는 id user_email/user_password 를 생성.
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password"

    click_button I18n.t("sessions.new.submit")

    # 로그인 성공 후 홈(feed)으로 리다이렉트되고 인증 전용 UI가 노출된다.
    assert_no_current_path new_user_session_path
    assert_text @user.name
  end
end
