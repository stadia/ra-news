# frozen_string_literal: true

# rbs_inline: enabled

class EmailVerificationsController < ApplicationController
  rate_limit to: 3, within: 10.minutes, only: :resend,
             by: -> { Current.user&.id },
             with: -> { redirect_to email_verification_path, alert: "잠시 후 다시 시도해주세요." }

  def show
    return redirect_to root_path if Current.user.email_verified?
    render Views::EmailVerifications::Show.new
  end

  def verify
    return redirect_to root_path if Current.user.email_verified?

    user = User.find_by_token_for(:email_verification, params[:token])

    if user && user == Current.user
      user.update!(email_verified_at: Time.current)
      redirect_to root_path, notice: "이메일 인증이 완료되었습니다."
    else
      redirect_to email_verification_path, alert: "인증 링크가 만료되었습니다. 새로운 인증 메일을 요청해주세요."
    end
  end

  def resend
    if Current.user.email_verified?
      redirect_to root_path, notice: "이미 인증된 계정입니다."
    else
      EmailVerificationMailer.verify(Current.user).deliver_later
      redirect_to email_verification_path, notice: "인증 메일을 다시 발송했습니다."
    end
  end
end
