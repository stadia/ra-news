# Devise Migration Design

Rails 8.1 빌트인 인증(Current, Authentication concern, has_secure_password)에서 Devise 젬으로 마이그레이션한다. 기존 사용자 데이터를 보존하며, 향후 OAuth2 연동을 위한 기반을 마련한다.

## 결정 사항

- **기존 사용자 유지**: bcrypt 호환으로 비밀번호 변경 없이 마이그레이션
- **Devise 모듈**: database_authenticatable, registerable, recoverable, validatable, rememberable (5개)
- **기존 인증 코드 완전 제거**: Session 모델, Current 클래스, Authentication concern 삭제
- **Phlex 뷰 재활용**: Devise 커스텀 컨트롤러에서 기존 Phlex 뷰 렌더링
- **점진적 마이그레이션**: 단계별 적용 및 검증

## 1. 데이터베이스 마이그레이션

### 컬럼 변경 (users 테이블)
- `password_digest` → `encrypted_password` 리네이밍
- `email_address` → `email` 리네이밍
- `reset_password_token` (string, unique index) 추가
- `reset_password_sent_at` (datetime) 추가
- `remember_created_at` (datetime) 추가
- 기존 인덱스를 새 컬럼명에 맞게 업데이트

### 테이블 제거
- `sessions` 테이블 드롭 (Devise는 Warden 쿠키 기반 세션 사용)

## 2. 모델 변경

### User 모델
- `has_secure_password` 제거
- `devise :database_authenticatable, :registerable, :recoverable, :validatable, :rememberable` 추가
- `email_address` 참조를 `email`로 변경
- 이메일/비밀번호 커스텀 validation은 Devise validatable이 대체
- `name`, `username`, `roles`, associations 등 기존 커스텀 코드 유지

### 제거
- `Session` 모델 (`app/models/session.rb`)
- `Current` 클래스 (`app/models/current.rb`)

### 전체 치환
- `Current.user` → `current_user`
- `Current.session` 참조 제거

## 3. 컨트롤러 및 라우팅

### Devise 커스텀 컨트롤러
- `Users::SessionsController < Devise::SessionsController` — 로그인
- `Users::RegistrationsController < Devise::RegistrationsController` — 회원가입/프로필
- `Users::PasswordsController < Devise::PasswordsController` — 비밀번호 재설정

### 제거
- `SessionsController` (기존)
- `PasswordsController` (기존)
- `Authentication` concern
- `UsersController`의 인증 관련 액션 (new, create)

### UsersController 잔존 액션
- `show` — 프로필 페이지 (공개)
- 나머지 프로필 관련 액션은 Devise registrations 컨트롤러로 통합

### 라우팅
```ruby
devise_for :users, path: '', path_names: {
  sign_in: 'login', sign_out: 'logout', sign_up: 'signup',
  password: 'passwords', edit: 'account/edit'
}, controllers: {
  sessions: 'users/sessions',
  registrations: 'users/registrations',
  passwords: 'users/passwords'
}
```

### 인증 패턴 전환
- `require_authentication` → `authenticate_user!`
- `allow_unauthenticated_access` → `skip_before_action :authenticate_user!`
- `authenticated?` → `user_signed_in?`

## 4. 뷰 및 메일러

### Phlex 뷰 재활용
- 기존 뷰를 Devise 컨벤션 경로로 이동:
  - `app/views/sessions/` → `app/views/users/sessions/`
  - `app/views/passwords/` → `app/views/users/passwords/`
  - `app/views/users/` (회원가입) → `app/views/users/registrations/`
- 폼 URL을 Devise 헬퍼로 변경
- `email_address` 필드명 → `email`

### 메일러
- `PasswordsMailer` 제거 → Devise 내장 mailer 사용
- 필요시 `app/views/devise/mailer/`에서 템플릿 커스터마이징

## 5. 영향 범위

### 코드 전체 치환이 필요한 항목
- `Current.user` → `current_user` (컨트롤러, 뷰, Honeybadger context 등)
- `email_address` → `email` (모델, 뷰, 컨트롤러, 메일러, 테스트)
- `authenticated?` → `user_signed_in?`

### 연관 시스템 확인 필요
- Federails (ActivityPub) — User 모델 변경 영향
- Honeybadger context — `Current.user` → `current_user`
- Rate limiting — Devise lockable 미사용이므로 기존 rate_limit 유지 또는 제거 판단
- Push subscriptions — User association 유지

## 향후 계획
- OAuth2: `devise :omniauthable` 모듈 추가 + omniauth 젬 설치
- Confirmable: `email_verified_at` 활용하여 이메일 인증 활성화
