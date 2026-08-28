# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class Api::V1::BaseController < ApplicationController
  # CSRF 면제를 무조건 걸면 안 된다. Devise는 `skip_session_storage = [:http_auth]`라
  # 세션 쿠키만 가진 요청도 `authenticate_user!`를 통과하므로, 교차 출처 HTML 폼이
  # 그대로 쓰기 액션에 도달한다. 실제 JSON 요청과 Bearer 요청만 면제한다 —
  # 둘 다 HTML 폼으로는 만들 수 없고 fetch로는 preflight에 걸린다.
  skip_before_action :verify_authenticity_token, if: :skip_csrf_for_api_request?, raise: false
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "parameter_missing", parameter: e.param }, status: :bad_request
  end

  private

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
