# 이메일 인증 설계 문서

**날짜:** 2026-03-16
**브랜치:** feature/user_confirm
**상태:** 승인됨

---

## 개요

회원가입 후 이메일 인증을 통해 계정을 활성화하는 기능. 인증 전 로그인은 가능하지만, 인증이 필요한 페이지 접근 시 이메일 인증 요청 페이지로 리다이렉트된다.

---

## 1. 데이터 모델

### DB 변경

```
users 테이블에 email_verified_at:datetime 컬럼 추가 (null 허용)
```

기존 유저는 `email_verified_at = null` 상태로 유지. 마이그레이션에서 기존 유저 데이터 수정 불필요.

### User 모델

```ruby
generates_token_for :email_verification, expires_in: 24.hours do
  [email_address, email_verified_at]
end

def email_verified?
  email_verified_at.present?
end
```

- `email_address`와 `email_verified_at` 둘 다 digest에 포함
  - 인증 완료 후 `email_verified_at` 변경 → 토큰 무효화 (재사용 불가)
  - 이메일 변경 후 `email_address` 변경 → 이전 토큰 무효화 (구 이메일로 발급된 토큰 차단)
- 토큰 유효시간: **24시간**
- PostgreSQL `datetime` 컬럼은 마이크로초 정밀도를 제공하므로 digest 충돌 위험 없음

### 이메일 변경 시 처리

사용자가 `email_address`를 변경하면 `email_verified_at`을 `nil`로 초기화하여 재인증을 요구한다.

```ruby
before_save :clear_email_verification_on_email_change

private

def clear_email_verification_on_email_change
  self.email_verified_at = nil if email_address_changed?
end
```

---

## 2. 플로우

### 회원가입 플로우

1. `UsersController#create` → `@user.save` 성공
2. `EmailVerificationMailer.verify(@user).deliver_later` 호출
3. 세션 시작 (`start_new_session_for @user`)
4. `/email_verification` 으로 리다이렉트

### 인증 플로우

1. 사용자가 메일의 인증 링크 클릭 (`GET /email_verification/:token`)
2. `User.find_by_email_verification_token!(token)` 검증
3. 성공 시 `user.update!(email_verified_at: Time.current)`
4. 루트 페이지로 리다이렉트 + "이메일 인증이 완료되었습니다" 성공 메시지

### 인증 필요 페이지 접근 제어

`Authentication` concern에 `require_verified_email` 메서드 추가:

```ruby
def require_verified_email
  return if Current.user&.email_verified?
  redirect_to email_verification_path, alert: "이메일 인증이 필요합니다."
end
```

인증이 필요한 컨트롤러/액션에 `before_action :require_verified_email`로 적용. `require_authentication` 이후에 실행되므로 로그인이 전제된다. 초기에는 `CommentsController` 등 쓰기 액션에 적용한다.

---

## 3. 컨트롤러

### `EmailVerificationsController`

| 액션 | HTTP | 경로 | 설명 |
|------|------|------|------|
| `show` | GET | `/email_verification` | 인증 요청 페이지 (재발송 버튼 포함) |
| `verify` | GET | `/email_verification/:token` | 토큰 검증 후 인증 완료 |
| `resend` | POST | `/email_verification/resend` | 인증 메일 재발송 |

- `verify`는 이메일 링크에서 클릭되는 GET 요청이므로 `update`(PATCH)가 아닌 커스텀 액션으로 정의
- `show`/`verify` 비로그인 접근 → `require_authentication`이 로그인 페이지로 리다이렉트, `return_to_after_authenticating`에 URL 저장 → 로그인 후 자동 복귀
- `show` 접근 시 이미 인증된 유저면 루트로 리다이렉트
- **봇 계정** (`has_role?(:bot)`): `require_verified_email` 가드 제외

> **UX 트레이드오프:** 다른 기기에서 인증 링크 클릭 시 로그인 먼저 요구. 의도된 동작이며 `return_to_after_authenticating`으로 로그인 후 자동 인증 완료.

### 라우트

`resource` (singular) 는 `:member`/`:collection` 구분이 없으므로 `on:` 옵션 없이 블록 안에 직접 선언한다.

```ruby
resource :email_verification, only: [:show] do
  get  ":token", action: :verify, as: :verify_email_verification
  post :resend
end
```

생성되는 경로:
- `email_verification_path` → `GET /email_verification`
- `verify_email_verification_path(token)` → `GET /email_verification/:token`
- `resend_email_verification_path` → `POST /email_verification/resend`

---

## 4. 메일러 & 뷰

### `EmailVerificationMailer`

```ruby
class EmailVerificationMailer < ApplicationMailer
  def verify(user)
    @user = user
    mail subject: "이메일 인증을 완료해주세요", to: user.email_address
  end
end
```

### 메일 뷰 (`app/views/email_verification_mailer/verify.html.erb`)

- 사용자 이름 표시
- 24시간 유효한 인증 링크 버튼
- `verify_email_verification_url(@user.generate_token_for(:email_verification))`

### 인증 요청 페이지 (`app/views/email_verifications/show.html.erb`)

- "인증 메일을 발송했습니다" 안내 메시지
- 재발송 버튼 (`POST /email_verification/resend`)

---

## 5. 에러 처리 & 엣지 케이스

| 상황 | 처리 |
|------|------|
| 만료/유효하지 않은 토큰 클릭 | `ActiveSupport::MessageVerifier::InvalidSignature` rescue → "인증 링크가 만료되었습니다" 알림 + 인증 요청 페이지로 리다이렉트 |
| 이미 인증된 토큰 재클릭 | 루트로 리다이렉트 (토큰이 `email_verified_at` digest로 자동 무효화) |
| 재발송 시 이미 인증된 유저 | 루트로 리다이렉트 + "이미 인증된 계정입니다" |
| 비로그인 상태에서 `show` 페이지 접근 | 기존 `require_authentication`이 로그인 페이지로 리다이렉트 |
| 비로그인 상태에서 토큰 링크 클릭 | 기존 `require_authentication`이 로그인 페이지로 리다이렉트 |
| 이메일 변경 후 기존 토큰 클릭 | `email_verified_at`이 nil로 초기화되어 토큰 무효화, 만료 처리와 동일 |

### 재발송 rate limiting

`resend` 액션에 rate limiting 적용 (기존 `SessionsController`와 동일한 패턴):

```ruby
rate_limit to: 3, within: 10.minutes, only: :resend,
           with: -> { redirect_to email_verification_path, alert: "잠시 후 다시 시도해주세요." }
```

---

## 6. 파일 목록

### 신규 생성
- `db/migrate/YYYYMMDD_add_email_verified_at_to_users.rb`
- `app/controllers/email_verifications_controller.rb`
- `app/mailers/email_verification_mailer.rb`
- `app/views/email_verification_mailer/verify.html.erb`
- `app/views/email_verification_mailer/verify.text.erb`
- `app/views/email_verifications/show.html.erb`

### 수정
- `app/models/user.rb` — `generates_token_for`, `email_verified?`, `clear_email_verification_on_email_change`
- `app/controllers/users_controller.rb` — 회원가입 후 메일 발송 + 리다이렉트
- `app/controllers/concerns/authentication.rb` — `require_verified_email` 추가
- `config/routes.rb` — `email_verification` 라우트 추가
