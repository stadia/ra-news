# Email Verification Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 회원가입 시 인증 메일을 발송하고, 인증 링크 클릭 시 이메일 인증을 완료하며, 인증 전 사용자가 인증 필요 페이지에 접근할 경우 인증 요청 페이지로 리다이렉트한다.

**Architecture:** Rails `generates_token_for :email_verification`으로 24시간 유효 토큰 발급. 인증 상태는 `users.email_verified_at` 컬럼으로 관리. `Authentication` concern에 `require_verified_email` 가드 추가, 필요한 컨트롤러에 `before_action`으로 적용.

**Tech Stack:** Rails 7.1+, has_secure_password, Minitest, Phlex (뷰), ActionMailer (이메일)

---

## Chunk 1: 데이터 모델 & User 모델

## Chunk 2: 메일러 & 라우트

## Chunk 3: 컨트롤러 & 뷰

## Chunk 4: 회원가입 연동 & 인증 가드

---

## Chunk 1: 데이터 모델 & User 모델

### 파일 목록

| 파일 | 작업 |
|------|------|
| `db/migrate/TIMESTAMP_add_email_verified_at_to_users.rb` | 신규 생성 |
| `app/models/user.rb` | 수정 — `generates_token_for`, `email_verified?`, `before_save` |
| `test/fixtures/users.yml` | 수정 — `email_verified_at` 필드 추가 |
| `test/models/user_test.rb` | 수정 — 이메일 인증 관련 테스트 추가 |

---

### Task 1: DB 마이그레이션 — email_verified_at 컬럼 추가

**Files:**
- Create: `db/migrate/TIMESTAMP_add_email_verified_at_to_users.rb`

- [ ] **Step 1: 마이그레이션 생성**

```bash
bin/rails generate migration AddEmailVerifiedAtToUsers email_verified_at:datetime
```

생성된 파일 확인: `db/migrate/YYYYMMDDHHMMSS_add_email_verified_at_to_users.rb`

- [ ] **Step 2: 마이그레이션 내용 확인**

생성된 파일이 아래와 같은지 확인한다 (자동 생성되므로 수정 불필요):

```ruby
class AddEmailVerifiedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_verified_at, :datetime
  end
end
```

- [ ] **Step 3: 마이그레이션 실행**

```bash
bin/rails db:migrate
```

Expected: `== AddEmailVerifiedAtToUsers: migrated`

- [ ] **Step 4: 테스트 DB에도 적용**

```bash
bin/rails db:migrate RAILS_ENV=test
```

- [ ] **Step 5: schema.rb에 컬럼 추가됐는지 확인**

`db/schema.rb`의 `users` 테이블에 `t.datetime "email_verified_at"` 줄이 추가됐어야 한다.

- [ ] **Step 6: 커밋**

```bash
git add db/migrate/ db/schema.rb
git commit -m "feat: add email_verified_at column to users"
```

---

### Task 2: User 모델 — 이메일 인증 관련 메서드 추가

**Files:**
- Modify: `app/models/user.rb`
- Modify: `test/fixtures/users.yml`
- Modify: `test/models/user_test.rb`

- [ ] **Step 1: fixture에 email_verified_at 추가**

`test/fixtures/users.yml`에서 각 유저 항목에 인증 상태를 추가한다. 대부분의 유저는 인증된 상태로 설정하고, 테스트용 미인증 유저를 추가한다:

기존 유저 8개(`john`, `jane`, `admin`, `korean_user`, `user_with_spaces`, `minimal_user`, `one`, `two`) 전부에 `email_verified_at` 추가. `unverified_user`는 생략 → DB에서 `nil`로 처리됨.

```yaml
john:
  email_address: john@example.com
  name: 존 도
  password_digest: <%= password_digest %>
  roles:
    - user
    - editor
    - bot
  email_verified_at: <%= 1.day.ago %>

jane:
  email_address: jane@example.com
  name: 제인 스미스
  password_digest: <%= password_digest %>
  roles:
    - user
    - bot
  email_verified_at: <%= 1.day.ago %>

admin:
  email_address: admin@example.com
  name: 관리자
  password_digest: <%= admin_password_digest %>
  roles:
    - user
    - admin
  email_verified_at: <%= 1.day.ago %>

korean_user:
  email_address: korean@example.com
  name: 김철수
  password_digest: <%= password_digest %>
  roles:
    - user
    - bot
  email_verified_at: <%= 1.day.ago %>

user_with_spaces:
  email_address: spaces@example.com
  name: 홍 길 동
  password_digest: <%= password_digest %>
  roles:
    - user
  email_verified_at: <%= 1.day.ago %>

minimal_user:
  email_address: minimal@example.com
  name: 최소
  password_digest: <%= password_digest %>
  roles:
    - user
  email_verified_at: <%= 1.day.ago %>

one:
  email_address: one@example.com
  name: 사용자 일
  password_digest: <%= password_digest %>
  roles:
    - user
  email_verified_at: <%= 1.day.ago %>

two:
  email_address: two@example.com
  name: 사용자 이
  password_digest: <%= password_digest %>
  roles:
    - user
  email_verified_at: <%= 1.day.ago %>

# 미인증 유저 (테스트용)
unverified_user:
  email_address: unverified@example.com
  name: 미인증 사용자
  password_digest: <%= password_digest %>
  roles:
    - user
```

- [ ] **Step 2: 실패할 테스트 작성**

`test/models/user_test.rb`에 아래 테스트 블록을 추가한다 (기존 `# ========== Edge Cases` 섹션 위에):

```ruby
# ========== Email Verification Tests ==========

test "email_verified?는 email_verified_at이 설정된 경우 true를 반환해야 한다" do
  user = users(:john)
  assert user.email_verified?
end

test "email_verified?는 email_verified_at이 nil인 경우 false를 반환해야 한다" do
  user = users(:unverified_user)
  assert_not user.email_verified?
end

test "이메일 변경 시 email_verified_at이 nil로 초기화되어야 한다" do
  user = users(:john)
  assert user.email_verified?

  user.update!(email_address: "newemail@example.com")
  assert_nil user.email_verified_at
  assert_not user.email_verified?
end

test "이메일 변경이 없을 경우 email_verified_at이 유지되어야 한다" do
  user = users(:john)
  original_verified_at = user.email_verified_at

  user.update!(name: "새로운 이름")
  assert_equal original_verified_at, user.reload.email_verified_at
end

test "generate_token_for :email_verification은 24시간 유효한 토큰을 생성해야 한다" do
  user = users(:unverified_user)
  token = user.generate_token_for(:email_verification)
  assert_not_nil token
  assert_equal user, User.find_by_token_for(:email_verification, token)
end

test "이메일 인증 완료 후 토큰은 무효화되어야 한다" do
  user = users(:unverified_user)
  token = user.generate_token_for(:email_verification)

  user.update!(email_verified_at: Time.current)

  assert_nil User.find_by_token_for(:email_verification, token)
end

test "이메일 변경 후 기존 토큰은 무효화되어야 한다" do
  user = users(:unverified_user)
  old_token = user.generate_token_for(:email_verification)

  user.update!(email_address: "changed@example.com")

  assert_nil User.find_by_token_for(:email_verification, old_token)
end

test "만료된 토큰은 무효화되어야 한다 (24시간 초과)" do
  user = users(:unverified_user)
  token = user.generate_token_for(:email_verification)

  travel_to 25.hours.from_now do
    assert_nil User.find_by_token_for(:email_verification, token)
  end
end
```

- [ ] **Step 3: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/models/user_test.rb -n "/Email Verification/"
```

Expected: 여러 테스트 FAIL — `undefined method 'email_verified?'` 또는 `unknown attribute 'email_verified_at'`

- [ ] **Step 4: User 모델 구현**

`app/models/user.rb`에 아래 코드를 추가한다. `has_many :articles` 아래에 토큰 설정을, 기존 `normalizes` 아래에 메서드들을 추가:

```ruby
# generates_token_for — 기존 normalizes 블록 아래에 추가
generates_token_for :email_verification, expires_in: 24.hours do
  [email_address, email_verified_at]
end

# Email verification callback — normalizes 블록 아래에 추가
before_save :clear_email_verification_on_email_change, if: :email_address_changed?
```

그리고 `def admin?` 위에 메서드 추가:

```ruby
def email_verified? #: bool
  email_verified_at.present?
end
```

`private` 섹션에 콜백 메서드 추가:

```ruby
def clear_email_verification_on_email_change
  self.email_verified_at = nil
end
```

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/models/user_test.rb -n "/Email Verification/"
```

Expected: 모든 테스트 PASS

- [ ] **Step 6: 전체 User 테스트 실행 — 기존 테스트 깨지지 않음 확인**

```bash
bin/rails test test/models/user_test.rb
```

Expected: 모든 테스트 PASS

- [ ] **Step 7: 커밋**

```bash
git add app/models/user.rb test/models/user_test.rb test/fixtures/users.yml
git commit -m "feat: add email verification to User model"
```

---

## Chunk 2: 메일러 & 라우트

### 파일 목록

| 파일 | 작업 |
|------|------|
| `app/mailers/email_verification_mailer.rb` | 신규 생성 |
| `app/views/email_verification_mailer/verify.html.erb` | 신규 생성 |
| `app/views/email_verification_mailer/verify.text.erb` | 신규 생성 |
| `test/mailers/email_verification_mailer_test.rb` | 신규 생성 |
| `test/mailers/previews/email_verification_mailer_preview.rb` | 신규 생성 |
| `config/routes.rb` | 수정 — email_verification 라우트 추가 |

---

### Task 3: EmailVerificationMailer

**Files:**
- Create: `app/mailers/email_verification_mailer.rb`
- Create: `app/views/email_verification_mailer/verify.html.erb`
- Create: `app/views/email_verification_mailer/verify.text.erb`
- Create: `test/mailers/email_verification_mailer_test.rb`
- Create: `test/mailers/previews/email_verification_mailer_preview.rb`

- [ ] **Step 1: 실패할 테스트 작성**

`test/mailers/email_verification_mailer_test.rb` 파일 생성:

```ruby
# frozen_string_literal: true

require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  test "verify 메일은 올바른 수신자와 제목을 가져야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    assert_equal [ user.email_address ], mail.to
    assert_equal "이메일 인증을 완료해주세요", mail.subject
  end

  test "verify 메일 본문에 인증 링크가 포함되어야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    # 메일러가 토큰을 생성하므로, 링크 경로 패턴으로 검증
    assert_match "email_verification", mail.html_part.body.to_s
    assert_match "email_verification", mail.text_part.body.to_s
  end

  test "verify 메일 본문에 사용자 이름이 포함되어야 한다" do
    user = users(:unverified_user)
    mail = EmailVerificationMailer.verify(user)

    assert_match user.name, mail.html_part.body.to_s
    assert_match user.name, mail.text_part.body.to_s
  end
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/mailers/email_verification_mailer_test.rb
```

Expected: FAIL — `uninitialized constant EmailVerificationMailer`

- [ ] **Step 3: 메일러 구현**

`app/mailers/email_verification_mailer.rb` 생성:

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class EmailVerificationMailer < ApplicationMailer
  def verify(user)
    @user = user
    @token = user.generate_token_for(:email_verification)
    mail subject: "이메일 인증을 완료해주세요", to: user.email_address
  end
end
```

- [ ] **Step 4: HTML 메일 뷰 생성**

`app/views/email_verification_mailer/verify.html.erb` 생성:

```html
<p><%= @user.name %>님, 안녕하세요.</p>

<p>아래 버튼을 클릭하여 이메일 인증을 완료해주세요.<br>
이 링크는 24시간 동안 유효합니다.</p>

<p>
  <%= link_to "이메일 인증하기", verify_email_verification_url(@token) %>
</p>

<p>본인이 요청하지 않은 경우 이 메일을 무시하셔도 됩니다.</p>
```

- [ ] **Step 5: 텍스트 메일 뷰 생성**

`app/views/email_verification_mailer/verify.text.erb` 생성:

```
<%= @user.name %>님, 안녕하세요.

아래 링크를 클릭하여 이메일 인증을 완료해주세요.
이 링크는 24시간 동안 유효합니다.

<%= verify_email_verification_url(@token) %>

본인이 요청하지 않은 경우 이 메일을 무시하셔도 됩니다.
```

- [ ] **Step 6: 라우트 추가 (테스트가 URL 헬퍼를 필요로 함)**

`config/routes.rb`에서 `resources :passwords` 아래에 추가:

> **주의:** `resource` 블록 내부에서 `as:` 를 지정하면 Rails가 부모 리소스 이름을 자동으로 붙여 헬퍼 이름이 중복된다. 따라서 토큰 검증 라우트는 블록 바깥에 별도로 선언한다.

```ruby
resource :email_verification, only: [:show] do
  post :resend
end
get "email_verification/:token", to: "email_verifications#verify", as: :verify_email_verification
```

생성되는 경로:
- `email_verification_path` → `GET /email_verification`
- `verify_email_verification_path(token)` → `GET /email_verification/:token`
- `resend_email_verification_path` → `POST /email_verification/resend`

- [ ] **Step 7: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/mailers/email_verification_mailer_test.rb
```

Expected: 모든 테스트 PASS

- [ ] **Step 8: 메일러 Preview 생성**

`test/mailers/previews/email_verification_mailer_preview.rb` 생성:

```ruby
# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/email_verification_mailer/verify
  def verify
    EmailVerificationMailer.verify(User.first)
  end
end
```

- [ ] **Step 9: 커밋**

```bash
git add app/mailers/email_verification_mailer.rb \
        app/views/email_verification_mailer/ \
        test/mailers/email_verification_mailer_test.rb \
        test/mailers/previews/email_verification_mailer_preview.rb \
        config/routes.rb
git commit -m "feat: add EmailVerificationMailer and routes"
```

---

## Chunk 3: 컨트롤러 & 뷰

### 파일 목록

| 파일 | 작업 |
|------|------|
| `app/controllers/email_verifications_controller.rb` | 신규 생성 |
| `app/views/email_verifications/show.rb` | 신규 생성 (Phlex) |
| `test/controllers/email_verifications_controller_test.rb` | 신규 생성 |

---

### Task 4: EmailVerificationsController

**Files:**
- Create: `app/controllers/email_verifications_controller.rb`
- Create: `app/views/email_verifications/show.rb`
- Create: `test/controllers/email_verifications_controller_test.rb`

컨트롤러가 다루는 액션:
- `show` — 인증 요청 페이지 (재발송 버튼)
- `verify` — 토큰 검증 후 인증 완료
- `resend` — 인증 메일 재발송

- [ ] **Step 1: 실패할 테스트 작성**

`test/controllers/email_verifications_controller_test.rb` 생성:

```ruby
# frozen_string_literal: true

require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  # ========== show ==========

  test "비로그인 상태에서 show 접근 시 로그인 페이지로 리다이렉트" do
    get email_verification_path
    assert_redirected_to new_session_path
  end

  test "로그인 + 미인증 상태에서 show 접근 시 인증 요청 페이지 표시" do
    user = users(:unverified_user)
    sign_in_as(user)

    get email_verification_path
    assert_response :ok
  end

  test "이미 인증된 유저가 show 접근 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)

    get email_verification_path
    assert_redirected_to root_path
  end

  # ========== verify ==========

  test "비로그인 상태에서 verify 토큰 링크 클릭 시 로그인 페이지로 리다이렉트" do
    user = users(:unverified_user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)
    assert_redirected_to new_session_path
  end

  test "유효한 토큰으로 verify 시 email_verified_at이 설정되어 루트로 리다이렉트" do
    user = users(:unverified_user)
    sign_in_as(user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)

    assert_redirected_to root_path
    assert_not_nil user.reload.email_verified_at
    assert_equal "이메일 인증이 완료되었습니다.", flash[:notice]
  end

  test "만료/유효하지 않은 토큰으로 verify 시 인증 요청 페이지로 리다이렉트" do
    user = users(:unverified_user)
    sign_in_as(user)

    get verify_email_verification_path("invalid_token")
    assert_redirected_to email_verification_path
    assert_equal "인증 링크가 만료되었습니다. 새로운 인증 메일을 요청해주세요.", flash[:alert]
  end

  test "이미 인증된 유저가 verify 접근 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)
    token = user.generate_token_for(:email_verification)

    get verify_email_verification_path(token)
    assert_redirected_to root_path
  end

  # ========== resend ==========

  test "비로그인 상태에서 resend 요청 시 로그인 페이지로 리다이렉트" do
    post resend_email_verification_path
    assert_redirected_to new_session_path
  end

  test "미인증 유저가 resend 요청 시 메일이 발송됨" do
    user = users(:unverified_user)
    sign_in_as(user)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post resend_email_verification_path
    end

    assert_redirected_to email_verification_path
    assert_equal "인증 메일을 다시 발송했습니다.", flash[:notice]
  end

  test "이미 인증된 유저가 resend 요청 시 루트로 리다이렉트" do
    user = users(:john)
    sign_in_as(user)

    post resend_email_verification_path
    assert_redirected_to root_path
    assert_equal "이미 인증된 계정입니다.", flash[:notice]
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/controllers/email_verifications_controller_test.rb
```

Expected: FAIL — `uninitialized constant EmailVerificationsController`

- [ ] **Step 3: 컨트롤러 구현**

`app/controllers/email_verifications_controller.rb` 생성:

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class EmailVerificationsController < ApplicationController
  rate_limit to: 3, within: 10.minutes, only: :resend,
             with: -> { redirect_to email_verification_path, alert: "잠시 후 다시 시도해주세요." }

  def show
    return redirect_to root_path if Current.user.email_verified?
    render Views::EmailVerifications::Show.new
  end

  def verify
    return redirect_to root_path if Current.user.email_verified?

    user = User.find_by_token_for(:email_verification, params[:token])

    if user && user == Current.user
      user.update!(email_verified_at: Time.current)
      redirect_to root_path, notice: "이메일 인증이 완료되었습니다."
    else
      redirect_to email_verification_path, alert: "인증 링크가 만료되었습니다. 새로운 인증 메일을 요청해주세요."
    end
  end

  def resend
    if Current.user.email_verified?
      redirect_to root_path, notice: "이미 인증된 계정입니다."
    else
      EmailVerificationMailer.verify(Current.user).deliver_later
      redirect_to email_verification_path, notice: "인증 메일을 다시 발송했습니다."
    end
  end
end
```

- [ ] **Step 4: Phlex 뷰 생성**

`app/views/email_verifications/show.rb` 생성:

```ruby
# frozen_string_literal: true

class Views::EmailVerifications::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def view_template
    content_for :title, "이메일 인증"

    div(class: "space-y-6 max-w-6xl mx-auto") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "이메일 인증" }

      div(class: "space-y-4") do
        p(class: "text-slate-300") {
          "회원가입 시 입력하신 이메일 주소로 인증 메일을 발송했습니다."
        }
        p(class: "text-slate-300") {
          "메일함을 확인하시고 인증 링크를 클릭해주세요. 링크는 24시간 동안 유효합니다."
        }
      end

      form_tag(resend_email_verification_path, method: :post, class: "mt-4") do
        render RubyUI::Button.new(
          type: "submit",
          variant: :outline,
          size: :lg,
          class: "rounded-md border border-slate-600 text-slate-300 hover:bg-slate-700"
        ) { "인증 메일 재발송" }
      end
    end
  end
end
```

> **참고:** `Views::EmailVerifications::Show`는 `Phlex::Rails::Helpers::FormTag`를 include해야 할 수 있다. 기존 뷰 코드를 참고하여 필요한 helper를 추가한다.

- [ ] **Step 5: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/controllers/email_verifications_controller_test.rb
```

Expected: 모든 테스트 PASS

- [ ] **Step 6: 커밋**

```bash
git add app/controllers/email_verifications_controller.rb \
        app/views/email_verifications/show.rb \
        test/controllers/email_verifications_controller_test.rb
git commit -m "feat: add EmailVerificationsController and show view"
```

---

## Chunk 4: 회원가입 연동 & 인증 가드

### 파일 목록

| 파일 | 작업 |
|------|------|
| `app/controllers/users_controller.rb` | 수정 — create 액션에 메일 발송 + 리다이렉트 |
| `app/controllers/concerns/authentication.rb` | 수정 — `require_verified_email` 추가 |
| `test/controllers/users_controller_test.rb` | 신규 생성 또는 수정 |

---

### Task 5: UsersController — 회원가입 시 인증 메일 발송

**Files:**
- Modify: `app/controllers/users_controller.rb`
- Create/Modify: `test/controllers/users_controller_test.rb`

- [ ] **Step 1: 실패할 테스트 작성**

`test/controllers/users_controller_test.rb` 생성:

```ruby
# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "회원가입 성공 시 인증 메일이 발송되어야 한다" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post user_path, params: {
        user: {
          email_address: "newuser@example.com",
          name: "새사용자",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "회원가입 성공 시 이메일 인증 요청 페이지로 리다이렉트되어야 한다" do
    post user_path, params: {
      user: {
        email_address: "newuser2@example.com",
        name: "새사용자둘",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to email_verification_path
  end

  test "회원가입 성공 시 세션이 시작되어야 한다" do
    post user_path, params: {
      user: {
        email_address: "newuser3@example.com",
        name: "새사용자셋",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to email_verification_path
    # 세션 쿠키가 설정되어야 함
    assert_not_nil cookies[:session_id]
  end
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
bin/rails test test/controllers/users_controller_test.rb
```

Expected: FAIL — 현재 `new_session_path`로 리다이렉트되기 때문

- [ ] **Step 3: UsersController#create 수정**

`app/controllers/users_controller.rb`의 `create` 액션을 아래와 같이 수정:

```ruby
def create
  @user = User.new(user_params)

  respond_to do |format|
    if @user.save
      start_new_session_for @user
      EmailVerificationMailer.verify(@user).deliver_later
      format.html { redirect_to email_verification_path, notice: t("registration_success") }
    else
      format.html { render Views::Users::New.new(user: @user), status: :unprocessable_entity }
    end
  end
end
```

> **필수 수정:** 현재 `user_params`는 `params.expect(user: [:email_address, :name])`만 허용한다. `create` 액션에서 비밀번호를 받으려면 반드시 아래와 같이 수정해야 한다:

```ruby
def user_params
  params.expect(user: [ :email_address, :name, :password, :password_confirmation ])
end
```

> **주의:** `password_params` (비밀번호 변경용) 와 `user_params` (회원가입/프로필 수정용) 는 별도로 유지한다. `update` 액션은 기존처럼 `password_update_request?` 로 분기한다.

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
bin/rails test test/controllers/users_controller_test.rb
```

Expected: 모든 테스트 PASS

- [ ] **Step 5: 커밋**

```bash
git add app/controllers/users_controller.rb \
        test/controllers/users_controller_test.rb
git commit -m "feat: send verification email on signup, redirect to email_verification"
```

---

### Task 6: Authentication concern — require_verified_email 가드

**Files:**
- Modify: `app/controllers/concerns/authentication.rb`

- [ ] **Step 1: require_verified_email 구현**

`app/controllers/concerns/authentication.rb`의 `private` 섹션에 추가:

```ruby
def require_verified_email
  return if Current.user&.email_verified?
  return if Current.user&.has_role?(:bot)
  redirect_to email_verification_path, alert: "이메일 인증이 필요합니다."
end
```

> **중요:** `require_verified_email`은 반드시 `require_authentication` **이후에** 실행되어야 한다. `allow_unauthenticated_access`가 적용된 액션(비로그인 허용)에는 절대 적용하지 않는다. `Current.user`가 설정된 (로그인된) 상태에서만 동작한다.

- [ ] **Step 2: 가드를 UsersController에 적용**

`CommentsController`는 비로그인 댓글 작성을 허용하므로 적용 대상이 아니다. 로그인이 필수인 `UsersController`의 프로필 수정/삭제 액션에 적용한다:

`app/controllers/users_controller.rb`에서 기존 `before_action :set_user` 아래에 추가:

```ruby
before_action :require_verified_email, except: %i[ new create ]
```

- [ ] **Step 3: 테스트 작성**

`test/controllers/users_controller_test.rb`에 아래 테스트 추가:

```ruby
test "미인증 유저가 프로필 수정 페이지 접근 시 이메일 인증 요청 페이지로 리다이렉트" do
  user = users(:unverified_user)
  post session_path, params: { email_address: user.email_address, password: "password" }

  get edit_users_path
  assert_redirected_to email_verification_path
  assert_equal "이메일 인증이 필요합니다.", flash[:alert]
end

test "인증된 유저는 프로필 수정 페이지에 접근 가능" do
  user = users(:john)
  post session_path, params: { email_address: user.email_address, password: "password" }

  get edit_users_path
  assert_response :ok
end
```

- [ ] **Step 4: 테스트 실행**

```bash
bin/rails test test/controllers/users_controller_test.rb
```

Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add app/controllers/concerns/authentication.rb \
        app/controllers/users_controller.rb \
        test/controllers/users_controller_test.rb
git commit -m "feat: add require_verified_email guard to Authentication concern"
```

---

### Task 7: 전체 테스트 실행 & 최종 확인

- [ ] **Step 1: 전체 테스트 스위트 실행**

```bash
bin/rails test
```

Expected: 모든 테스트 PASS, 실패 없음

- [ ] **Step 2: 라우트 확인**

```bash
bin/rails routes | grep email_verification
```

Expected 출력:
```
    email_verification GET    /email_verification(.:format)          email_verifications#show
verify_email_verification GET    /email_verification/:token(.:format)   email_verifications#verify
  resend_email_verification POST   /email_verification/resend(.:format)   email_verifications#resend
```

- [ ] **Step 3: 최종 커밋 (필요시)**

```bash
git add -A
git status  # 스테이지되지 않은 파일 없는지 확인
```

---

## 전체 파일 목록 요약

### 신규 생성
| 파일 | 설명 |
|------|------|
| `db/migrate/TIMESTAMP_add_email_verified_at_to_users.rb` | email_verified_at 컬럼 마이그레이션 |
| `app/mailers/email_verification_mailer.rb` | 인증 메일 발송 |
| `app/views/email_verification_mailer/verify.html.erb` | HTML 메일 뷰 |
| `app/views/email_verification_mailer/verify.text.erb` | 텍스트 메일 뷰 |
| `app/controllers/email_verifications_controller.rb` | show, verify, resend 액션 |
| `app/views/email_verifications/show.rb` | 인증 요청 페이지 (Phlex) |
| `test/mailers/email_verification_mailer_test.rb` | 메일러 테스트 |
| `test/mailers/previews/email_verification_mailer_preview.rb` | 메일 미리보기 |
| `test/controllers/email_verifications_controller_test.rb` | 컨트롤러 테스트 |
| `test/controllers/users_controller_test.rb` | 회원가입 흐름 테스트 |

### 수정
| 파일 | 변경 내용 |
|------|-----------|
| `app/models/user.rb` | `generates_token_for`, `email_verified?`, `before_save` 추가 |
| `app/controllers/users_controller.rb` | `create`에 메일 발송 + 리다이렉트 변경, `user_params`에 password 추가 |
| `app/controllers/concerns/authentication.rb` | `require_verified_email` 메서드 추가 |
| `app/controllers/users_controller.rb` | `before_action :require_verified_email, except: %i[new create]` 추가, `user_params`에 password 필드 추가 |
| `config/routes.rb` | `resource :email_verification` 라우트 추가 |
| `test/fixtures/users.yml` | `email_verified_at` 필드 추가, `unverified_user` fixture 추가 |
| `test/models/user_test.rb` | 이메일 인증 관련 테스트 추가 |
