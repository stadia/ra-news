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
- `email` 컬럼에 unique index 생성 (기존에 없음)

### 테이블 제거
- `sessions` 테이블 드롭 (foreign key 먼저 제거 후 cascade)

### 마이그레이션 검증
- 마이그레이션 후 콘솔에서 `user.valid_password?('known_password')` 로 bcrypt 호환성 확인

## 2. 모델 변경

### User 모델
- `has_secure_password` 제거
- `devise :database_authenticatable, :registerable, :recoverable, :validatable, :rememberable` 추가
- `email_address` 참조를 `email`로 변경 (`full_name` 메서드 포함)
- `has_many :sessions` association 제거
- 이메일/비밀번호 커스텀 validation은 Devise validatable이 대체
- `name`, `username`, `roles`, 기타 associations 유지

### 제거
- `Session` 모델 (`app/models/session.rb`)
- `Current` 클래스 (`app/models/current.rb`)

### 전체 치환
- `Current.user` → `current_user`
- `Current.session` 참조 제거
- `email_address` → `email` (모델, 뷰, 컨트롤러, 테스트 전체)

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

### AuthenticatedConstraint 재작성
기존 `Session` 모델 기반에서 Warden 기반으로 변경:
```ruby
class AuthenticatedConstraint
  def matches?(request)
    warden = request.env['warden']
    warden&.authenticated?(:user) && warden.user(:user)&.admin?
  end
end
```

### Madmin 컨트롤러
`app/controllers/madmin/application_controller.rb`의 인증 게이트를 명시적으로 업데이트:
- `authenticated?` → `user_signed_in?`
- `Current.user` → `current_user`

### UsersController 잔존 액션
- `show` — 프로필 페이지 (공개)
- 나머지 프로필 관련 액션은 Devise registrations 컨트롤러로 통합

### 라우팅
기존 수동 라우트(`login`, `logout`, `signup`) 제거 후 Devise 라우트로 교체:
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

### Phlex 컴포넌트 업데이트 대상
- `app/components/users/form.rb`
- `app/components/users/pwd_form.rb`
- `app/components/users/user.rb`
- `app/madmin/resources/user_resource.rb`

### 메일러
- `PasswordsMailer` 제거 → Devise 내장 mailer 사용
- 필요시 `app/views/devise/mailer/`에서 템플릿 커스터마이징

## 5. i18n 및 설정

### Devise initializer
- `config.case_insensitive_keys = [:email]`
- `config.strip_whitespace_keys = [:email]`
- 기타 Devise 기본 설정

### 한국어 locale
- `config/locales/devise.ko.yml` 생성 — 에러 메시지 한국어화 (현재 커스텀 한국어 메시지 유지)

## 6. 영향 범위

### 연관 시스템
- **Federails** — `email_address` 미참조, 안전. `username`, `name` 필드 변경 없음
- **Honeybadger context** — `Current.user` → `current_user`
- **Rate limiting concern** — `Current.user`, `authenticated?` 참조 업데이트
- **Push subscriptions** — User association 유지

### 테스트 파일 업데이트
- `test/models/user_test.rb`
- `test/models/current_test.rb` (삭제)
- `test/test_helper.rb`
- `test/controllers/posts_controller_test.rb`
- 기타 `email_address`, `Current.user` 참조 테스트

### email_verified_at 컬럼
- 현재 마이그레이션에서는 유지 (drop하지 않음)
- 향후 confirmable 추가 시 Devise 컬럼(`confirmed_at` 등)으로 전환 판단

## 향후 계획
- OAuth2: `devise :omniauthable` 모듈 추가 + omniauth 젬 설치
- Confirmable: Devise 컬럼 추가 후 이메일 인증 활성화
