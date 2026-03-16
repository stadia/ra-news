# frozen_string_literal: true

require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  test "verify 메일은 올바른 수신자와 제목을 가져야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    assert_equal [ user.email_address ], mail.to
    assert_equal "이메일 인증을 완료해주세요", mail.subject
  end

  test "verify 메일 본문에 인증 링크가 포함되어야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    # 메일러가 토큰을 생성하므로, 링크 경로 패턴으로 검증
    assert_match "email_verification", mail.html_part.body.to_s
    assert_match "email_verification", mail.text_part.body.to_s
  end

  test "verify 메일 본문에 사용자 이름이 포함되어야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    assert_match user.name, mail.html_part.body.to_s
    assert_match user.name, mail.text_part.body.to_s
  end
end
