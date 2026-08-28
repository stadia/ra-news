# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class JsonFailureApp < Devise::FailureApp
  def respond
    if json_request?
      json_error_response
    else
      super
    end
  end

  private

  # 본문 없는 Bearer DELETE는 Content-Type이 비어 format이 HTML로 잡힌다.
  # Authorization 헤더까지 봐야 만료·무효 토큰이 302 로그인 리다이렉트가 아니라
  # 401 JSON으로 떨어져 API 클라이언트가 원인을 알 수 있다.
  def json_request?
    request.format.json? || request.content_type.to_s.include?("json") || bearer_request?
  end

  def bearer_request?
    request.headers["Authorization"].to_s.start_with?("Bearer ")
  end

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "unauthorized" }.to_json
  end
end
