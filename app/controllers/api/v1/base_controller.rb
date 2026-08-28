# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::BaseController < ApplicationController
  # CSRF 면제를 무조건 걸면 안 된다. api/v1도 ApplicationController를 상속해
  # Warden 세션 직렬화를 그대로 쓰므로, 로그인 쿠키만 가진 요청이 `authenticate_user!`를
  # 통과한다(쿠키는 SameSite=Lax라 교차 출처 GET은 막히지만 top-level POST는 실려 간다).
  # 면제를 무조건 걸면 교차 출처 HTML 폼이 그대로 쓰기 액션에 도달하므로,
  # 실제 JSON 요청과 Bearer 요청만 면제한다 — 둘 다 HTML 폼으로는 만들 수 없고
  # fetch로는 preflight에 걸린다.
  skip_before_action :verify_authenticity_token, if: :skip_csrf_for_api_request?, raise: false
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "parameter_missing", parameter: e.param }, status: :bad_request
  end

  private

  # 지원 밖 대상 타입은 API 클라이언트가 진단할 수 있도록 JSON 봉투로 돌려준다.
  # (404/400과 마찬가지로 기계 판독 가능한 `error` 키를 유지한다.)
  #: () -> void
  def render_unsupported_target_type
    render json: { error: "unsupported_target_type" }, status: :unprocessable_entity
  end

  # 본문 없는 DELETE는 Content-Type이 비어 `json_request?`가 거짓이므로,
  # Bearer 토큰 요청을 따로 허용해야 JWT 클라이언트가 막히지 않는다.
  #: () -> bool
  def skip_csrf_for_api_request?
    json_request? || bearer_request?
  end

  #: () -> bool
  def bearer_request?
    request.headers["Authorization"].to_s.start_with?("Bearer ")
  end
end
