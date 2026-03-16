# frozen_string_literal: true

# rbs_inline: enabled

class EmailVerificationMailer < ApplicationMailer
  def verify(user)
    @user = user
    @token = user.generate_token_for(:email_verification)
    mail subject: "이메일 인증을 완료해주세요", to: user.email_address
  end
end
