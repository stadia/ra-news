# OAuth Google/Apple Auth Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Google/Apple OAuth로 로그인과 회원가입을 지원하고, verified email 기반 기존 계정 연결과 username 보완 가입 흐름을 구현한다.

**Architecture:** Devise + OmniAuth callback 진입점을 추가하고, `oauth_accounts` 테이블로 provider 식별을 분리한다. OAuth callback에서는 기존 OAuth 계정 조회 → verified email 기반 기존 사용자 연결 → 신규 가입 보완 세션 진입 순으로 처리한다. 신규 가입 완료는 별도 서비스에서 `User`와 `OauthAccount`를 원자적으로 생성한다.

**Tech Stack:** Rails 8, Devise, OmniAuth, omniauth-google-oauth2, omniauth-apple, Phlex, PostgreSQL, Minitest

---

## 사전 확인 메모

- 현재 인증은 `User` 모델의 Devise(`database_authenticatable`, `confirmable`, `jwt_authenticatable`) 사용
- 회원가입 시 `signup_host`, `locale`은 `Users::RegistrationsController#create`에서 현재 요청 기준으로 설정
- 로그인 화면은 `app/views/sessions/new.rb` Phlex 뷰 사용
- `username`은 필수이며 영문/숫자/밑줄/점만 허용
- Apple private relay(`privaterelay.appleid.com`)는 기존 계정 자동 연결 금지

## 구현 원칙

- RED → GREEN 순서로 진행
- provider verified email만 자동 연결 허용
- Apple private relay는 신규 플로우로만 진입
- 신규 OAuth 사용자는 username 제안/수정 단계를 반드시 거침
- provider verified email이면 `confirmed_at` 즉시 설정

---

### Task 1: Gem과 Devise OmniAuth 설정 추가

**Files:**
- Modify: `Gemfile`
- Modify: `app/models/user.rb`
- Modify: `config/initializers/devise.rb`
- Test: `test/models/user_test.rb`

**Step 1: 실패 테스트 추가**
- `User`가 `omniauthable` 설정을 포함하는지 검증하는 테스트 추가
- 필요한 provider 목록(`google_oauth2`, `apple`)을 기대하는 테스트 추가

**Step 2: 테스트 실패 확인**
- Run: `bin/rails test test/models/user_test.rb`
- Expected: omniAuth 관련 assertion 실패

**Step 3: 최소 구현**
- `Gemfile`에 `omniauth-google-oauth2`, `omniauth-apple` 추가
- `User`에 `:omniauthable, omniauth_providers: %i[google_oauth2 apple]` 추가
- `config/initializers/devise.rb`에 provider 설정 추가
  - ENV 기반 client_id / secret / team_id / key_id / pem key 참조
  - Apple scope/email/name 설정

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/models/user_test.rb`

**Step 5: Commit**
```bash
git add Gemfile app/models/user.rb config/initializers/devise.rb test/models/user_test.rb
git commit -m "feat: configure devise omniauth providers"
```

---

### Task 2: OAuth 계정 저장용 테이블과 모델 추가

**Files:**
- Create: `db/migrate/*_create_oauth_accounts.rb`
- Create: `app/models/oauth_account.rb`
- Modify: `app/models/user.rb`
- Test: `test/models/oauth_account_test.rb`
- Test: `test/models/user_test.rb`

**Step 1: 실패 테스트 작성**
- `OauthAccount` association/validation 테스트 작성
- `provider + uid` 유니크 테스트 작성
- `User has_many :oauth_accounts` 테스트 추가

**Step 2: 실패 확인**
- Run: `bin/rails test test/models/oauth_account_test.rb test/models/user_test.rb`

**Step 3: 최소 구현**
- migration 생성:
  - `user:references`
  - `provider:string, null: false`
  - `uid:string, null: false`
  - `email:string`
  - `email_verified:boolean, null: false, default: false`
  - `raw_info:jsonb, null: false, default: {}`
  - unique index on `[:provider, :uid]`
  - optional unique index on `[:user_id, :provider]`
- `OauthAccount` 모델 구현
  - `belongs_to :user`
  - validation for provider, uid
- `User`에 `has_many :oauth_accounts, dependent: :destroy`

**Step 4: 테스트 통과 확인**
- Run: `bin/rails db:migrate`
- Run: `bin/rails test test/models/oauth_account_test.rb test/models/user_test.rb`

**Step 5: Commit**
```bash
git add db/migrate app/models/oauth_account.rb app/models/user.rb test/models/oauth_account_test.rb test/models/user_test.rb
git commit -m "feat: add oauth account model"
```

---

### Task 3: OmniAuth 라우팅과 callback 컨트롤러 골격 추가

**Files:**
- Modify: `config/routes.rb`
- Create or Modify: `app/controllers/users/omniauth_callbacks_controller.rb`
- Test: `test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 1: 실패 테스트 작성**
- Google callback route 존재 테스트
- Apple callback route 존재 테스트
- callback 진입 시 처리 서비스 호출 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 3: 최소 구현**
- Devise routes에 `controllers: { omniauth_callbacks: "users/omniauth_callbacks" }` 연결
- `Users::OmniauthCallbacksController` 생성
- `google_oauth2`, `apple` 액션에서 공통 핸들러 호출

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 5: Commit**
```bash
git add config/routes.rb app/controllers/users/omniauth_callbacks_controller.rb test/controllers/users/omniauth_callbacks_controller_test.rb
git commit -m "feat: add omniauth callback endpoints"
```

---

### Task 4: OAuth payload 정규화 객체/서비스 구현

**Files:**
- Create: `app/functions/oauth_accounts/auth_result_builder.rb`
- Test: `test/functions/oauth_accounts/auth_result_builder_test.rb`

**Step 1: 실패 테스트 작성**
- Google payload에서 email/name/uid/provider/email_verified 추출 테스트
- Apple payload에서 relay 여부 판별 테스트
- Apple private relay 판별 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/functions/oauth_accounts/auth_result_builder_test.rb`

**Step 3: 최소 구현**
- auth hash를 받아 normalized result 반환
- 포함 필드 예시:
  - provider
  - uid
  - email
  - email_verified
  - name
  - relay_email?
  - raw_info
- private relay 판단 로직 구현

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/functions/oauth_accounts/auth_result_builder_test.rb`

**Step 5: Commit**
```bash
git add app/functions/oauth_accounts/auth_result_builder.rb test/functions/oauth_accounts/auth_result_builder_test.rb
git commit -m "feat: normalize oauth provider payloads"
```

---

### Task 5: 기존 사용자 연결 규칙 서비스 구현

**Files:**
- Create: `app/functions/oauth_accounts/user_matcher.rb`
- Test: `test/functions/oauth_accounts/user_matcher_test.rb`

**Step 1: 실패 테스트 작성**
- 기존 `OauthAccount` 있으면 해당 사용자 반환
- verified email이면 기존 `User.email` 자동 연결
- unverified email이면 자동 연결 안 함
- Apple relay email이면 자동 연결 안 함

**Step 2: 실패 확인**
- Run: `bin/rails test test/functions/oauth_accounts/user_matcher_test.rb`

**Step 3: 최소 구현**
- 우선순위:
  1. `OauthAccount.find_by(provider:, uid:)`
  2. verified + non-relay + email present면 `User.find_by(email:)`
  3. 나머지는 nil
- module보다 상태가 필요 없다면 module + `module_function` 우선 검토

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/functions/oauth_accounts/user_matcher_test.rb`

**Step 5: Commit**
```bash
git add app/functions/oauth_accounts/user_matcher.rb test/functions/oauth_accounts/user_matcher_test.rb
git commit -m "feat: add oauth user matching rules"
```

---

### Task 6: username 제안기 구현

**Files:**
- Create: `app/functions/oauth_accounts/username_suggester.rb`
- Test: `test/functions/oauth_accounts/username_suggester_test.rb`

**Step 1: 실패 테스트 작성**
- name/email 기반 기본 username 제안 테스트
- 허용 문자만 남기는 테스트
- 중복 시 suffix 붙이는 테스트
- 길이/최소 길이 보정 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/functions/oauth_accounts/username_suggester_test.rb`

**Step 3: 최소 구현**
- 입력 후보: name → email local-part 순
- 정규화: `[a-zA-Z0-9_.]` 외 제거/치환
- 너무 짧으면 fallback 추가
- 중복이면 `_1`, `_2` 등 suffix

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/functions/oauth_accounts/username_suggester_test.rb`

**Step 5: Commit**
```bash
git add app/functions/oauth_accounts/username_suggester.rb test/functions/oauth_accounts/username_suggester_test.rb
git commit -m "feat: suggest usernames for oauth signups"
```

---

### Task 7: callback 분기 서비스 구현 (로그인 vs 신규가입 준비)

**Files:**
- Create: `app/functions/oauth_accounts/callback_service.rb`
- Modify: `app/controllers/users/omniauth_callbacks_controller.rb`
- Test: `test/functions/oauth_accounts/callback_service_test.rb`
- Test: `test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 1: 실패 테스트 작성**
- 기존 oauth account면 로그인 결과 반환
- 기존 email 매칭이면 oauth account 연결 후 로그인 결과 반환
- 신규 사용자면 보완 세션 payload 반환

**Step 2: 실패 확인**
- Run: `bin/rails test test/functions/oauth_accounts/callback_service_test.rb test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 3: 최소 구현**
- 서비스 결과 타입 예시:
  - `:sign_in`
  - `:complete_signup`
  - `:error`
- 기존 user 매칭 시 `OauthAccount` 생성/연결
- 신규 플로우는 session에 임시 oauth payload 저장

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/functions/oauth_accounts/callback_service_test.rb test/controllers/users/omniauth_callbacks_controller_test.rb`

**Step 5: Commit**
```bash
git add app/functions/oauth_accounts/callback_service.rb app/controllers/users/omniauth_callbacks_controller.rb test/functions/oauth_accounts/callback_service_test.rb test/controllers/users/omniauth_callbacks_controller_test.rb
git commit -m "feat: route oauth callbacks into sign-in flow"
```

---

### Task 8: username 보완용 가입 화면/컨트롤러 추가

**Files:**
- Create: `app/controllers/users/oauth_registrations_controller.rb`
- Create: `app/views/users/oauth_signup.rb`
- Modify: `config/routes.rb`
- Test: `test/controllers/users/oauth_registrations_controller_test.rb`

**Step 1: 실패 테스트 작성**
- 임시 oauth session이 있으면 화면 렌더링
- suggested username 표시 테스트
- 세션 없으면 로그인 화면으로 리다이렉트 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/controllers/users/oauth_registrations_controller_test.rb`

**Step 3: 최소 구현**
- GET: 제안된 username과 readonly email/name 표시
- Phlex 뷰 작성
- RubyUI form/button 사용
- locale/host는 세션이 아니라 요청 기준으로 마무리 저장 예정

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/controllers/users/oauth_registrations_controller_test.rb`

**Step 5: Commit**
```bash
git add app/controllers/users/oauth_registrations_controller.rb app/views/users/oauth_signup.rb config/routes.rb test/controllers/users/oauth_registrations_controller_test.rb
git commit -m "feat: add oauth username completion screen"
```

---

### Task 9: 최종 신규 가입 서비스 구현

**Files:**
- Create: `app/functions/oauth_accounts/registration_service.rb`
- Modify: `app/controllers/users/oauth_registrations_controller.rb`
- Test: `test/functions/oauth_accounts/registration_service_test.rb`
- Test: `test/controllers/users/oauth_registrations_controller_test.rb`

**Step 1: 실패 테스트 작성**
- username 확정 시 `User` + `OauthAccount` 생성 테스트
- `confirmed_at` 즉시 설정 테스트
- `signup_host`, `locale`가 현재 요청 기준 저장되는지 테스트
- username validation 실패 시 다시 폼 표시 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/functions/oauth_accounts/registration_service_test.rb test/controllers/users/oauth_registrations_controller_test.rb`

**Step 3: 최소 구현**
- service에서 transaction으로 생성
- user 속성:
  - email
  - name
  - username
  - locale
  - signup_host
  - confirmed_at (verified email일 때)
  - 랜덤 비밀번호 생성
- oauth account 연결
- 성공 시 sign in

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/functions/oauth_accounts/registration_service_test.rb test/controllers/users/oauth_registrations_controller_test.rb`

**Step 5: Commit**
```bash
git add app/functions/oauth_accounts/registration_service.rb app/controllers/users/oauth_registrations_controller.rb test/functions/oauth_accounts/registration_service_test.rb test/controllers/users/oauth_registrations_controller_test.rb
git commit -m "feat: complete oauth user registration"
```

---

### Task 10: 로그인 화면에 OAuth 버튼 추가

**Files:**
- Modify: `app/views/sessions/new.rb`
- Possibly Create: `app/components/auth/oauth_button.rb`
- Modify: `config/locales/ko.yml`
- Modify: `config/locales/ja.yml`
- Test: `test/controllers/users/sessions_controller_test.rb`

**Step 1: 실패 테스트 작성**
- 로그인 화면에 Google/Apple 버튼 노출 테스트
- 버튼 href 검증 테스트

**Step 2: 실패 확인**
- Run: `bin/rails test test/controllers/users/sessions_controller_test.rb`

**Step 3: 최소 구현**
- 로그인 화면에 OAuth 섹션 추가
- RubyUI 없으면 앱 컴포넌트로 버튼 통일
- i18n 키 추가

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/controllers/users/sessions_controller_test.rb`

**Step 5: Commit**
```bash
git add app/views/sessions/new.rb app/components/auth/oauth_button.rb config/locales/ko.yml config/locales/ja.yml test/controllers/users/sessions_controller_test.rb
 git commit -m "feat: add oauth sign in buttons"
```

---

### Task 11: 통합 인증 시나리오 테스트 추가

**Files:**
- Create or Modify: `test/integration/oauth_auth_flow_test.rb`
- Possibly Modify: `test/test_helper.rb`

**Step 1: 실패 테스트 작성**
- Google 기존 계정 연결 시나리오
- Apple relay 신규 가입 보완 시나리오
- 신규 OAuth 가입 완료 시 로그인 완료 시나리오

**Step 2: 실패 확인**
- Run: `bin/rails test test/integration/oauth_auth_flow_test.rb`

**Step 3: 최소 구현 보완**
- 필요한 stub/helper 추가
- OmniAuth mock auth 설정 보강

**Step 4: 테스트 통과 확인**
- Run: `bin/rails test test/integration/oauth_auth_flow_test.rb`

**Step 5: Commit**
```bash
git add test/integration/oauth_auth_flow_test.rb test/test_helper.rb
 git commit -m "test: cover oauth auth flows"
```

---

### Task 12: 전체 검증

**Files:**
- Modify only if validation failures demand it

**Step 1: 관련 테스트 실행**
```bash
bin/rails test \
  test/models/oauth_account_test.rb \
  test/functions/oauth_accounts/auth_result_builder_test.rb \
  test/functions/oauth_accounts/user_matcher_test.rb \
  test/functions/oauth_accounts/username_suggester_test.rb \
  test/functions/oauth_accounts/callback_service_test.rb \
  test/functions/oauth_accounts/registration_service_test.rb \
  test/controllers/users/omniauth_callbacks_controller_test.rb \
  test/controllers/users/oauth_registrations_controller_test.rb \
  test/controllers/users/sessions_controller_test.rb \
  test/integration/oauth_auth_flow_test.rb
```

**Step 2: Rails validate 실행**
```bash
rails 'ai:tool[validate]' files=app/models/user.rb,app/models/oauth_account.rb,app/controllers/users/omniauth_callbacks_controller.rb,app/controllers/users/oauth_registrations_controller.rb,app/views/sessions/new.rb level=rails
```

**Step 3: graphify 갱신**
```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

**Step 4: 전체 테스트 / 품질 게이트 실행**
```bash
bin/rails test
bin/rake quality
```

**Step 5: 결과 기록 후 Commit**
```bash
git add .
git commit -m "feat: add google and apple oauth authentication"
```

---

## 구현 시 주의사항

- `email` 컬럼은 실제 DB상 `email_address`일 수 있으므로, Devise alias 동작과 schema를 매 단계 재검증할 것
- Apple은 첫 로그인 때만 name/email 일부를 줄 수 있으니 `raw_info` 보존이 필요
- JWT 로그인과 충돌하지 않게 HTML OAuth와 JSON API auth 경계를 유지할 것
- callback 실패 시 로그인 화면으로 안전하게 복귀하고, 한국어 alert 제공
- 신규 OAuth 가입 중단 시 세션 정리 경로를 둘 것

## 추천 커밋 순서 요약

1. Devise OmniAuth provider 설정
2. `oauth_accounts` 모델/마이그레이션
3. callback endpoint
4. payload 정규화/매칭/username 제안 서비스
5. callback orchestration
6. username 보완 화면
7. 최종 가입 서비스
8. 로그인 화면 OAuth 버튼
9. 통합 테스트
10. 전체 검증
