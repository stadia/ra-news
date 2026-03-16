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

기존 유저는 `email_verified_at = null` 상태로 유지. 마이그레이션에서 기존 유저 처리 불필요.

### User 모델

```ruby
generates_token_for :email_verification, expires_in: 24.hours do
  email_verified_at
end

def email_verified?
  email_verified_at.present?
end
```

- `email_verified_at`을 token digest에 포함 → 인증 완료 후 토큰 자동 무효화 (재사용 불가)
- 토큰 유효시간: **24시간**

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
4. 루트 페이지로 리다이렉트 + 성공 메시지

### 인증 요청 페이지 접근 제어

- `Authentication` concern에 `require_verified_email` 메서드 추가
- 인증이 필요한 컨트롤러/액션에 `before_action :require_verified_email` 적용
- 미인증 유저 접근 시 `/email_verification` 으로 리다이렉트

---

## 3. 컨트롤러

### `EmailVerificationsController`

| 액션 | 경로 | 설명 |
|------|------|------|
| `show` | `GET /email_verification` | 인증 요청 페이지 (재발송 버튼 포함) |
| `update` | `GET /email_verification/:token` | 토큰 검증 후 인증 완료 |
| `resend` | `POST /email_verification/resend` | 인증 메일 재발송 |

### 라우트

```ruby
resource :email_verification, only: [:show] do
  get  ":token", action: :update, as: :verify
  post :resend
end
```

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
- `email_verification_verify_url(@user.generate_token_for(:email_verification))`

### 인증 요청 페이지 (`app/views/email_verifications/show.html.erb`)

- "인증 메일을 발송했습니다" 안내 메시지
- 재발송 버튼 (`POST /email_verification/resend`)
- 이미 인증된 유저 접근 시 루트로 리다이렉트

---

## 5. Authentication Concern 확장

```ruby
def require_verified_email
  return if Current.user&.email_verified?
  redirect_to email_verification_path, alert: "이메일 인증이 필요합니다."
end
```

---

## 6. 에러 처리 & 엣지 케이스

| 상황 | 처리 |
|------|------|
| 만료된 토큰 클릭 | "인증 링크가 만료되었습니다" 알림 + 인증 요청 페이지로 리다이렉트 |
| 이미 인증된 토큰 재클릭 | 루트로 리다이렉트 (토큰이 `email_verified_at` digest로 자동 무효화) |
| 재발송 시 이미 인증된 유저 | 루트로 리다이렉트 + "이미 인증된 계정입니다" |
| 비로그인 상태에서 토큰 링크 클릭 | 로그인 페이지로 리다이렉트 |
| 기존 유저 (`email_verified_at` null) | 로그인 후 인증 요청 페이지 표시 |

---

## 7. 파일 목록

### 신규 생성
- `db/migrate/YYYYMMDD_add_email_verified_at_to_users.rb`
- `app/controllers/email_verifications_controller.rb`
- `app/mailers/email_verification_mailer.rb`
- `app/views/email_verification_mailer/verify.html.erb`
- `app/views/email_verification_mailer/verify.text.erb`
- `app/views/email_verifications/show.html.erb`

### 수정
- `app/models/user.rb` — `generates_token_for`, `email_verified?`
- `app/controllers/users_controller.rb` — 회원가입 후 메일 발송 + 리다이렉트
- `app/controllers/concerns/authentication.rb` — `require_verified_email` 추가
- `config/routes.rb` — `email_verification` 라우트 추가
