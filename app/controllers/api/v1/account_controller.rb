# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 현재 로그인 사용자 프로필 조회. 웹의 계정 수정 화면(Users::RegistrationsController#edit)이
# 겸하던 JSON 응답을 여기로 옮겼다.
class Api::V1::AccountController < Api::V1::BaseController
  def show
    response.headers["Cache-Control"] = "no-store"
    render json: { user: UserSerializer.new(current_user).serializable_hash }
  end
end
