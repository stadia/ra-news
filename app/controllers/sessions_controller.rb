# frozen_string_literal: true

# rbs_inline: enabled

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    redirect_to root_url and return if authenticated?
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to root_url
    else
      redirect_to new_session_path, alert: "이메일 주소나 비밀번호를 다시 확인해 주세요."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
