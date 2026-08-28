# frozen_string_literal: true

require "test_helper"

# 테스트 환경은 기본적으로 `allow_forgery_protection = false`라 CSRF 동작이
# 관찰되지 않는다. 이 테스트는 요청 단위로 보호를 켜고, `skip_before_action`의
# `if:`/`only:` 조합이 OR로 평가되어 HTML POST까지 면제되는 회귀를 막는다.
class CsrfProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @original_allow_forgery_protection
  end

  test "CSRF 토큰 없는 HTML 로그인 POST는 거부된다" do
    user = users(:john)

    post user_session_path, params: { user: { email: user.email, password: "password" } }

    assert_response :unprocessable_entity
  end

  test "CSRF 토큰 없는 JSON 로그인 POST는 허용된다" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json

    assert_response :success
  end

  test "CSRF 토큰 없는 HTML API 로그인 POST는 거부된다" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } }

    assert_response :unprocessable_entity
  end

  test "JSON format suffix does not bypass CSRF for form encoded API login" do
    user = users(:john)

    post "#{api_v1_auth_login_path}.json",
         params: { user: { email: user.email, password: "password" } }

    assert_response :unprocessable_entity
  end

  test "본문 없는 익명 API 로그아웃은 CSRF 검증 없이 허용된다" do
    delete api_v1_auth_logout_path

    assert_response :no_content
  end

  test "CSRF 토큰 없는 세션 쿠키 로그아웃은 거부된다" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json

    delete api_v1_auth_logout_path

    assert_response :unprocessable_entity
  end

  test "본문 없는 Bearer API 로그아웃은 CSRF 검증 없이 허용된다" do
    user = users(:john)

    post api_v1_auth_login_path,
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]
    cookies.to_hash.keys.each { |key| cookies.delete(key) }

    delete api_v1_auth_logout_path, headers: { "Authorization" => token }

    assert_response :no_content
    assert_equal 0, user.refresh_tokens.active.count
  end

  test "CSRF 토큰 없는 HTML 부스트 POST는 거부된다" do
    post api_v1_article_boost_path(articles(:ruby_article))

    assert_response :unprocessable_entity
  end
end
