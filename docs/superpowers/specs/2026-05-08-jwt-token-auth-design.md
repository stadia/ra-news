# JWT 토큰 인증 도입

- 작성일: 2026-05-08
- 상태: 승인됨 (구현 대기)

## 목적

모바일/외부 API 클라이언트가 사용할 JWT 기반 인증을 도입한다. 기존 Devise 세션 기반 웹 인증은 유지하고, JSON 요청에 한해 `Authorization: Bearer <token>` 인증을 추가한다.

## 범위

### 포함
- `devise-jwt` gem 도입 및 설정
- JWT denylist 모델 (`JwtDenylist`)
- 자체 구현 refresh token 모델 (`RefreshToken`) 및 회전 로직
- 로그인 시 access + refresh token 발급
- `POST /api/v1/auth/refresh` 엔드포인트로 토큰 갱신 (신규 앱 전용 API는 `/api/v1` namespace 사용)
- 로그아웃 시 access(jti denylist) + 사용자 refresh token 일괄 무효화
- 다음 컨트롤러의 JSON 응답에 JWT 인증 적용:
  - `ArticlesController#index, #show`
  - `LikesController#create, #destroy`
  - `PostsController#create`
- JSON 401 응답을 위한 커스텀 `failure_app`
- 위 요소에 대한 Minitest 테스트

### 제외
- HTML 흐름의 인증 방식 변경 (Devise 세션 그대로)
- 기존 컨트롤러를 `/api/v1` 하위로 이전 (기존 라우트 그대로 두고 JWT만 추가)
- 위에 명시되지 않은 컨트롤러의 JWT 보호 (추후 별도 작업)

### Namespace 정책
신규 앱 전용 API 엔드포인트는 `/api/v1/...` namespace 하위에 배치한다 (예: `/api/v1/auth/refresh`). 기존 컨트롤러의 JSON 응답은 현재 라우트를 유지하고 JWT 인증 레이어만 추가한다.

## 아키텍처

### 인증 분기
- HTML 요청 → 기존 Devise 세션 (변경 없음)
- JSON 요청 → warden의 `:jwt_authenticatable` strategy가 `Authorization: Bearer …` 헤더 검증

`authenticate_user!` 호출은 그대로 두고, warden이 요청 형식과 헤더 유무에 따라 적절한 strategy를 선택한다.

### 토큰 정책
- **Access token**: 15분 만료. devise-jwt가 발급/검증. payload `jti`로 무효화 추적.
- **Refresh token**: 30일 만료. 자체 `RefreshToken` 모델에 digest로 저장. 사용 시 회전(이전 토큰 무효화 + 새 토큰 발급).

## 컴포넌트

### 1. `JwtDenylist` 모델
devise-jwt 표준 denylist 전략.

마이그레이션:
- `jti:string` (unique index)
- `exp:datetime`

```ruby
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
  self.table_name = "jwt_denylists"
end
```

### 2. `RefreshToken` 모델

마이그레이션:
- `user_id:references` (foreign key, indexed)
- `token_digest:string` (unique index, not null)
- `expires_at:datetime` (not null)
- `revoked_at:datetime`
- `created_at`, `updated_at`

```ruby
class RefreshToken < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  REFRESH_TTL = 30.days

  def self.issue(user)
    raw = SecureRandom.urlsafe_base64(64)
    record = create!(
      user: user,
      token_digest: digest(raw),
      expires_at: REFRESH_TTL.from_now
    )
    [record, raw]
  end

  def self.find_active_by_raw(raw)
    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
```

### 3. User 모델 변경
```ruby
devise :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
has_many :refresh_tokens, dependent: :destroy
```

### 4. `config/initializers/devise.rb` 추가
```ruby
config.jwt do |jwt|
  jwt.secret = Rails.application.credentials.devise_jwt_secret_key
  jwt.dispatch_requests = [["POST", %r{^/login$}]]
  jwt.revocation_requests = [["DELETE", %r{^/logout$}]]
  jwt.expiration_time = 15.minutes.to_i
end
```

`Rails.application.credentials.devise_jwt_secret_key`를 신규 키로 추가한다 (initial setup 단계).

### 5. `Users::SessionsController` 확장
- `respond_with(resource, _opts = {})` 오버라이드:
  - JSON 성공 시 devise-jwt가 응답 헤더 `Authorization`에 access token 세팅 (자동)
  - 추가로 body에 `{ user: { id:, email: }, refresh_token: <raw> }` 렌더
- `respond_to_on_destroy`: 로그아웃 시 `current_user.refresh_tokens.active.find_each(&:revoke!)` 호출 후 204 반환

### 6. `Api::V1::Auth::TokensController` (신규)
```ruby
class Api::V1::Auth::TokensController < ApplicationController
  skip_before_action :authenticate_user!
  respond_to :json

  def refresh
    raw = params.require(:refresh_token)
    record = RefreshToken.find_active_by_raw(raw)
    return render(json: { error: "invalid_refresh_token" }, status: :unauthorized) unless record

    user = record.user
    record.revoke!
    _new_record, new_raw = RefreshToken.issue(user)
    access_token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    render json: {
      access_token: access_token,
      refresh_token: new_raw,
      expires_in: 15.minutes.to_i
    }
  end
end
```

### 7. 커스텀 `failure_app`
JSON 인증 실패 시 401 + `{ error: "unauthorized" }` 반환.

```ruby
class JsonFailureApp < Devise::FailureApp
  def respond
    if request.format.json? || request.content_type =~ /json/
      json_error_response
    else
      super
    end
  end

  private

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "unauthorized" }.to_json
  end
end
```

`config/initializers/devise.rb`에 `config.warden { |m| m.failure_app = JsonFailureApp }` 추가.

### 8. 라우트
```ruby
namespace :api do
  namespace :v1 do
    namespace :auth do
      post :refresh, to: "tokens#refresh"
    end
  end
end
```

기존 `devise_for :users`는 그대로. devise-jwt가 `/login`, `/logout` 라우트의 dispatch/revocation을 자동 처리한다.

## 데이터 흐름

### 로그인
```
POST /login.json
Body: { user: { email, password } }

→ Devise 검증
→ 응답 헤더: Authorization: Bearer <access(15m)>
→ 응답 body: { user: { id, email }, refresh_token: <raw(30d)> }
```

### 보호된 요청
```
GET /articles.json
Header: Authorization: Bearer <access>

→ warden jwt strategy가 토큰 검증 + jti가 denylist에 없는지 확인
→ @current_user 세팅
→ 200 (JSON 응답)
```

### 토큰 갱신
```
POST /api/v1/auth/refresh
Body: { refresh_token }

→ digest로 active record 조회
→ 없으면 401 invalid_refresh_token
→ 있으면 revoke + 새 refresh 발급 + 새 access 인코딩
→ { access_token, refresh_token, expires_in: 900 }
```

### 로그아웃
```
DELETE /logout
Header: Authorization: Bearer <access>

→ devise-jwt가 access jti를 JwtDenylist에 추가
→ Users::SessionsController#respond_to_on_destroy가 user의 refresh 토큰 일괄 revoke
→ 204
```

## 에러 처리

| 상황 | 응답 |
|---|---|
| Access 누락/만료/변조/denylist | 401 `{ error: "unauthorized" }` (failure_app) |
| Refresh token 누락 | 400 (Strong Parameters `ActionController::ParameterMissing`) |
| Refresh token 무효/만료/revoked | 401 `{ error: "invalid_refresh_token" }` |

## 테스트 (Minitest)

- `RefreshTokenTest`
  - `issue` 시 raw가 평문 저장되지 않고 digest로만 보관됨
  - `active` scope: revoked / expired 제외
  - `find_active_by_raw`: 매칭/비매칭
  - `revoke!`: `revoked_at` 세팅 후 `active`에서 제외
- `JwtDenylistTest`
  - jti revoke 후 동일 토큰 재사용 거부
- `Users::SessionsControllerTest`
  - JSON 로그인: `Authorization` 응답 헤더 존재, body에 `refresh_token` 포함
  - JSON 로그아웃: 204, access jti가 denylist에 추가, 사용자 refresh 모두 revoked
- `Api::V1::Auth::TokensControllerTest`
  - 유효한 refresh로 호출 → 새 access/refresh 반환, 이전 refresh는 사용 불가 (회전)
  - 만료/revoked/존재하지 않는 refresh → 401
- `ArticlesControllerTest`
  - `GET /articles.json` 토큰 없으면 401
  - 유효 토큰이면 200, JSON 페이로드 정상
- `LikesControllerTest`
  - `POST /articles/:id/like.json` 토큰 없으면 401
  - 유효 토큰이면 정상 동작
- `PostsControllerTest`
  - `POST /articles/:id/posts.json` 토큰 없으면 401, 유효 토큰이면 정상

기존 HTML 테스트가 깨지지 않는지도 회귀 검증한다.

## 마이그레이션

1. `create_table :jwt_denylists` (jti string, exp datetime, jti에 unique index)
2. `create_table :refresh_tokens` (user_id references, token_digest string unique, expires_at, revoked_at, timestamps)

## 보안 고려사항

- `RefreshToken#token_digest`는 SHA256 해시로 저장 → DB 유출 시 raw 토큰 추출 불가
- Refresh 회전: 한 번 사용된 refresh는 즉시 revoke → 토큰 탈취 후 재사용 시 정상 사용자 영향 (이상 탐지 단서)
- Access TTL 짧게(15분) → 탈취된 access의 유효 기간 최소화
- `devise_jwt_secret_key`는 `secret_key_base`와 분리 → 회전 가능

## 비고

- 기존 `Federails::JwtMagic` 등 Federails가 사용하는 JWT 기능과 secret 충돌 없는지 initializer 추가 시 확인 필요. 별도 키(`devise_jwt_secret_key`)를 사용하므로 분리 보장됨.
