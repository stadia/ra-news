# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# JWT 발급/폐기 전용 세션 엔드포인트. Devise::SessionsController를 상속해
# 파라미터 인증·로그아웃 처리 로직을 그대로 재사용하고, 응답만 JSON으로 바꾼다.
# 액세스 토큰(JWT)은 devise-jwt가 dispatch_requests 매칭으로 Authorization
# 헤더에 실어주므로 여기서는 리프레시 토큰만 직접 발급한다.
class Api::V1::Auth::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, raise: false
  # create는 Devise가 `warden.authenticate!`로 파라미터 인증을 수행하므로
  # 선행 인증 필터를 걷어낸다(걸어두면 로그인 자체가 401이 된다).
  skip_before_action :authenticate_user!, only: :create

  respond_to :json

  def destroy
    current_user&.refresh_tokens&.active&.update_all(revoked_at: Time.current)
    super
  end

  private

  def respond_with(resource, _opts = {})
    _record, raw = RefreshToken.issue(resource)

    render json: {
      user: UserSerializer.new(resource).serializable_hash,
      refresh_token: raw
    }, status: :ok
  end

  def respond_to_on_destroy(non_navigational_status: :no_content)
    head :no_content
  end
end
