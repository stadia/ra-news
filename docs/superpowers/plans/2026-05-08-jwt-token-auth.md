# JWT 토큰 인증 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Devise 기반 웹 세션은 유지하면서 JSON 요청에 한해 JWT(Access + Refresh) 인증을 추가한다.

**Architecture:** `devise-jwt`가 access token을 발급/검증하고 `JwtDenylist`로 무효화한다. Refresh token은 `RefreshToken` 모델로 자체 구현(회전, digest 저장). 신규 앱 전용 엔드포인트는 `/api/v1/...` namespace, 기존 컨트롤러는 라우트 그대로 두고 JWT 보호만 적용.

**Tech Stack:** Rails 8.1, Ruby 4.0.3, Devise, devise-jwt, jwt, Minitest, fixtures.

**Spec:** `docs/superpowers/specs/2026-05-08-jwt-token-auth-design.md`

---

## File Structure

### 새로 생성
- `db/migrate/<ts>_create_jwt_denylists.rb`
- `db/migrate/<ts>_create_refresh_tokens.rb`
- `app/models/jwt_denylist.rb`
- `app/models/refresh_token.rb`
- `app/controllers/api/v1/auth/tokens_controller.rb`
- `app/lib/json_failure_app.rb`
- `test/models/jwt_denylist_test.rb`
- `test/models/refresh_token_test.rb`
- `test/controllers/api/v1/auth/tokens_controller_test.rb`

### 수정
- `Gemfile`
- `config/initializers/devise.rb`
- `app/models/user.rb`
- `app/controllers/users/sessions_controller.rb`
- `config/routes.rb`
- `test/controllers/articles_controller_test.rb`
- `test/controllers/likes_controller_test.rb`
- `test/controllers/posts_controller_test.rb`
- `test/controllers/users/sessions_controller_test.rb`

---

## Task 1: Add devise-jwt gem

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Add gem to Gemfile**

`Gemfile`의 auth 관련 섹션을 찾아 추가:

```ruby
gem "devise-jwt", "~> 0.12"
```

- [ ] **Step 2: Install**

```bash
eval "$(rbenv init -)" && bundle install
```

기대: `Bundle complete!` 출력. `Gemfile.lock`에 `devise-jwt` 항목 생성됨.

- [ ] **Step 3: Generate JWT secret credential**

```bash
eval "$(rbenv init -)" && bin/rails runner 'puts SecureRandom.hex(64)'
```

출력된 64바이트 hex 문자열을 복사. 그 후:

```bash
EDITOR="cat" bin/rails credentials:edit
```

(편집기 환경이 다르면 사용자에게 위임) 다음 키를 추가:

```yaml
devise_jwt_secret_key: <위에서_생성한_hex>
```

기대: `credentials.yml.enc` 변경 사항이 git status에 보임.

- [ ] **Step 4: Commit**

```bash
git add Gemfile Gemfile.lock config/credentials.yml.enc
git commit -m "Add devise-jwt gem and JWT secret credential"
```

---

## Task 2: JwtDenylist model + migration (TDD)

**Files:**
- Create: `db/migrate/<ts>_create_jwt_denylists.rb`
- Create: `app/models/jwt_denylist.rb`
- Create: `test/models/jwt_denylist_test.rb`

- [ ] **Step 1: Generate migration**

```bash
eval "$(rbenv init -)" && bin/rails generate migration CreateJwtDenylists jti:string:uniq exp:datetime
```

생성된 파일을 다음 내용으로 교체:

```ruby
class CreateJwtDenylists < ActiveRecord::Migration[8.1]
  def change
    create_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false

      t.timestamps
    end
    add_index :jwt_denylists, :jti, unique: true
  end
end
```

- [ ] **Step 2: Run migration**

```bash
eval "$(rbenv init -)" && bin/rails db:migrate
```

기대: `jwt_denylists` 테이블 생성됨.

- [ ] **Step 3: Write failing test**

`test/models/jwt_denylist_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class JwtDenylistTest < ActiveSupport::TestCase
  test "includes denylist revocation strategy" do
    assert_includes JwtDenylist.included_modules,
                    Devise::JWT::RevocationStrategies::Denylist
  end

  test "uses jwt_denylists table" do
    assert_equal "jwt_denylists", JwtDenylist.table_name
  end
end
```

- [ ] **Step 4: Run test to verify failure**

```bash
eval "$(rbenv init -)" && bin/rails test test/models/jwt_denylist_test.rb
```

기대: `NameError: uninitialized constant JwtDenylist`.

- [ ] **Step 5: Create model**

`app/models/jwt_denylist.rb`:

```ruby
# frozen_string_literal: true

class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylists"
end
```

- [ ] **Step 6: Run test to verify pass**

```bash
eval "$(rbenv init -)" && bin/rails test test/models/jwt_denylist_test.rb
```

기대: `2 runs, ... 0 failures`.

- [ ] **Step 7: Commit**

```bash
git add db/migrate app/models/jwt_denylist.rb test/models/jwt_denylist_test.rb db/schema.rb
git commit -m "Add JwtDenylist model for devise-jwt revocation"
```

---

## Task 3: RefreshToken model + migration (TDD)

**Files:**
- Create: `db/migrate/<ts>_create_refresh_tokens.rb`
- Create: `app/models/refresh_token.rb`
- Create: `test/models/refresh_token_test.rb`
- Create: `test/fixtures/refresh_tokens.yml`

- [ ] **Step 1: Generate migration**

```bash
eval "$(rbenv init -)" && bin/rails generate migration CreateRefreshTokens user:references token_digest:string:uniq expires_at:datetime revoked_at:datetime
```

생성된 파일을 다음 내용으로 교체:

```ruby
class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :refresh_tokens, :token_digest, unique: true
  end
end
```

- [ ] **Step 2: Run migration**

```bash
eval "$(rbenv init -)" && bin/rails db:migrate
```

- [ ] **Step 3: Create empty fixture file**

`test/fixtures/refresh_tokens.yml`:

```yaml
# 기본 fixture는 없음. 테스트에서 RefreshToken.issue로 동적 생성.
```

- [ ] **Step 4: Write failing test**

`test/models/refresh_token_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
  end

  test "issue returns record and raw token, stores digest only" do
    record, raw = RefreshToken.issue(@user)

    assert raw.is_a?(String)
    assert_operator raw.length, :>=, 64
    assert_not_equal raw, record.token_digest
    assert_equal Digest::SHA256.hexdigest(raw), record.token_digest
    assert_equal @user, record.user
    assert_in_delta RefreshToken::REFRESH_TTL.from_now, record.expires_at, 5
  end

  test "active scope excludes revoked and expired" do
    fresh, _raw = RefreshToken.issue(@user)
    revoked, _raw = RefreshToken.issue(@user)
    revoked.update!(revoked_at: Time.current)
    expired, _raw = RefreshToken.issue(@user)
    expired.update_columns(expires_at: 1.day.ago)

    assert_includes RefreshToken.active, fresh
    assert_not_includes RefreshToken.active, revoked
    assert_not_includes RefreshToken.active, expired
  end

  test "find_active_by_raw matches valid raw token" do
    record, raw = RefreshToken.issue(@user)

    assert_equal record, RefreshToken.find_active_by_raw(raw)
    assert_nil RefreshToken.find_active_by_raw("nope")
  end

  test "find_active_by_raw rejects revoked token" do
    record, raw = RefreshToken.issue(@user)
    record.revoke!

    assert_nil RefreshToken.find_active_by_raw(raw)
  end

  test "revoke! sets revoked_at" do
    record, _raw = RefreshToken.issue(@user)

    assert_nil record.revoked_at
    record.revoke!
    assert_not_nil record.reload.revoked_at
  end
end
```

- [ ] **Step 5: Run test to verify failure**

```bash
eval "$(rbenv init -)" && bin/rails test test/models/refresh_token_test.rb
```

기대: `NameError: uninitialized constant RefreshToken`.

- [ ] **Step 6: Create model**

`app/models/refresh_token.rb`:

```ruby
# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  REFRESH_TTL = 30.days

  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue(user)
    raw = SecureRandom.urlsafe_base64(64)
    record = create!(
      user: user,
      token_digest: digest(raw),
      expires_at: REFRESH_TTL.from_now
    )
    [ record, raw ]
  end

  def self.find_active_by_raw(raw)
    return nil if raw.blank?

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

- [ ] **Step 7: Run test to verify pass**

```bash
eval "$(rbenv init -)" && bin/rails test test/models/refresh_token_test.rb
```

기대: `5 runs, ... 0 failures`.

- [ ] **Step 8: Commit**

```bash
git add db/migrate app/models/refresh_token.rb test/models/refresh_token_test.rb test/fixtures/refresh_tokens.yml db/schema.rb
git commit -m "Add RefreshToken model with rotation support"
```

---

## Task 4: User model — JWT authenticatable

**Files:**
- Modify: `app/models/user.rb`

- [ ] **Step 1: Add JWT to devise modules and association**

`app/models/user.rb`의 `devise` 호출과 association 부근:

```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :validatable, :rememberable, :timeoutable, :confirmable,
       :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
```

`has_many :posts, dependent: :destroy` 줄 아래에 다음을 추가:

```ruby
has_many :refresh_tokens, dependent: :destroy
```

- [ ] **Step 2: Validate**

```bash
eval "$(rbenv init -)" && bin/rails runner 'puts User.devise_modules.inspect'
```

기대: 출력에 `:jwt_authenticatable` 포함.

- [ ] **Step 3: Run existing user tests to verify no regression**

```bash
eval "$(rbenv init -)" && bin/rails test test/models/user_test.rb
```

기대: 모든 테스트 통과.

- [ ] **Step 4: Commit**

```bash
git add app/models/user.rb
git commit -m "Wire User to devise-jwt and refresh tokens"
```

---

## Task 5: JsonFailureApp + Devise initializer

**Files:**
- Create: `app/lib/json_failure_app.rb`
- Modify: `config/initializers/devise.rb`

- [ ] **Step 1: Create JsonFailureApp**

`app/lib/json_failure_app.rb`:

```ruby
# frozen_string_literal: true

class JsonFailureApp < Devise::FailureApp
  def respond
    if json_request?
      json_error_response
    else
      super
    end
  end

  private

  def json_request?
    request.format.json? || request.content_type.to_s.include?("json")
  end

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "unauthorized" }.to_json
  end
end
```

- [ ] **Step 2: Update Devise initializer**

`config/initializers/devise.rb`를 열고 `Devise.setup do |config|` 블록 끝부분에 다음을 추가 (`end` 직전):

```ruby
  config.warden do |manager|
    manager.failure_app = JsonFailureApp
  end

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key
    jwt.dispatch_requests = [
      [ "POST", %r{^/login$} ]
    ]
    jwt.revocation_requests = [
      [ "DELETE", %r{^/logout$} ]
    ]
    jwt.expiration_time = 15.minutes.to_i
  end
```

- [ ] **Step 3: Boot check**

```bash
eval "$(rbenv init -)" && bin/rails runner 'puts "ok"'
```

기대: `ok` 출력. (initializer 에러가 있다면 boot가 실패)

- [ ] **Step 4: Commit**

```bash
git add app/lib/json_failure_app.rb config/initializers/devise.rb
git commit -m "Configure devise-jwt and JSON failure app"
```

---

## Task 6: Sessions controller — JSON login response (TDD)

**Files:**
- Modify: `app/controllers/users/sessions_controller.rb`
- Modify: `test/controllers/users/sessions_controller_test.rb` (또는 신규 생성)

- [ ] **Step 1: Check existing test file**

```bash
ls test/controllers/users/ 2>/dev/null
```

`sessions_controller_test.rb`가 없으면 신규 생성, 있으면 추가.

- [ ] **Step 2: Write failing test**

`test/controllers/users/sessions_controller_test.rb` (없으면 생성, 있으면 아래 테스트 추가):

```ruby
# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "JSON login returns Authorization header and refresh_token body" do
    post user_session_path(format: :json),
         params: { user: { email: @user.email, password: "password" } },
         as: :json

    assert_response :success
    assert_match(/^Bearer /, response.headers["Authorization"].to_s)

    body = JSON.parse(response.body)
    assert_equal @user.id, body.dig("user", "id")
    assert_equal @user.email, body.dig("user", "email")
    assert body["refresh_token"].present?
  end

  test "JSON login with bad password returns 401 JSON" do
    post user_session_path(format: :json),
         params: { user: { email: @user.email, password: "wrong" } },
         as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "unauthorized", body["error"]
  end

  test "JSON logout revokes user refresh tokens" do
    post user_session_path(format: :json),
         params: { user: { email: @user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]
    refresh_count_before = @user.refresh_tokens.active.count
    assert_operator refresh_count_before, :>=, 1

    delete destroy_user_session_path(format: :json),
           headers: { "Authorization" => token },
           as: :json

    assert_response :no_content
    assert_equal 0, @user.refresh_tokens.active.count
  end
end
```

- [ ] **Step 3: Run failing test**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/users/sessions_controller_test.rb
```

기대: 실패 (Authorization 헤더 없음, refresh_token body 없음).

- [ ] **Step 4: Update SessionsController**

`app/controllers/users/sessions_controller.rb`를 다음으로 교체:

```ruby
# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout -> { Components::Layout }

  respond_to :html, :json

  def new
    redirect_to root_url and return if user_signed_in?
    render Views::Sessions::New.new
  end

  private

  def respond_with(resource, _opts = {})
    if request.format.json?
      _record, raw = RefreshToken.issue(resource)
      render json: {
        user: { id: resource.id, email: resource.email },
        refresh_token: raw
      }, status: :ok
    else
      super
    end
  end

  def respond_to_on_destroy
    if request.format.json?
      current_user&.refresh_tokens&.active&.find_each(&:revoke!)
      head :no_content
    else
      super
    end
  end
end
```

- [ ] **Step 5: Run test to verify pass**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/users/sessions_controller_test.rb
```

기대: 3 runs, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/users/sessions_controller.rb test/controllers/users/sessions_controller_test.rb
git commit -m "Issue JWT and refresh token on JSON login, revoke on logout"
```

---

## Task 7: Api::V1::Auth::TokensController + route (TDD)

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/api/v1/auth/tokens_controller.rb`
- Create: `test/controllers/api/v1/auth/tokens_controller_test.rb`

- [ ] **Step 1: Add route**

`config/routes.rb`의 `Rails.application.routes.draw do` 블록 안, `devise_for :users` 다음 적당한 위치에 추가:

```ruby
namespace :api do
  namespace :v1 do
    namespace :auth do
      post :refresh, to: "tokens#refresh"
    end
  end
end
```

- [ ] **Step 2: Verify route**

```bash
eval "$(rbenv init -)" && bin/rails routes | grep api_v1_auth
```

기대: `POST /api/v1/auth/refresh` 라우트 표시됨.

- [ ] **Step 3: Write failing test**

`test/controllers/api/v1/auth/tokens_controller_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    _record, @raw_refresh = RefreshToken.issue(@user)
  end

  test "refresh rotates tokens" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["access_token"].present?
    assert body["refresh_token"].present?
    assert_not_equal @raw_refresh, body["refresh_token"]
    assert_equal 15.minutes.to_i, body["expires_in"]
  end

  test "old refresh token is revoked after rotation" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json
    assert_response :success

    # 같은 토큰 재사용 시도
    post api_v1_auth_refresh_path,
         params: { refresh_token: @raw_refresh },
         as: :json
    assert_response :unauthorized
  end

  test "invalid refresh token returns 401" do
    post api_v1_auth_refresh_path,
         params: { refresh_token: "garbage" },
         as: :json

    assert_response :unauthorized
    assert_equal "invalid_refresh_token", JSON.parse(response.body)["error"]
  end

  test "missing refresh_token returns 400" do
    post api_v1_auth_refresh_path, params: {}, as: :json

    assert_response :bad_request
  end
end
```

- [ ] **Step 4: Run failing test**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/api/v1/auth/tokens_controller_test.rb
```

기대: `NameError: uninitialized constant Api::V1::Auth::TokensController`.

- [ ] **Step 5: Create controller**

`app/controllers/api/v1/auth/tokens_controller.rb`:

```ruby
# frozen_string_literal: true

class Api::V1::Auth::TokensController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, raise: false
  respond_to :json

  rescue_from ActionController::ParameterMissing do
    render json: { error: "missing_refresh_token" }, status: :bad_request
  end

  def refresh
    raw = params.require(:refresh_token)
    record = RefreshToken.find_active_by_raw(raw)

    return render(json: { error: "invalid_refresh_token" }, status: :unauthorized) unless record

    user = record.user
    record.revoke!
    _new_record, new_raw = RefreshToken.issue(user)
    access_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    render json: {
      access_token: access_token,
      refresh_token: new_raw,
      expires_in: 15.minutes.to_i
    }
  end
end
```

- [ ] **Step 6: Run test to verify pass**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/api/v1/auth/tokens_controller_test.rb
```

기대: 4 runs, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add config/routes.rb app/controllers/api/v1/auth/tokens_controller.rb test/controllers/api/v1/auth/tokens_controller_test.rb
git commit -m "Add JWT refresh endpoint with token rotation"
```

---

## Task 8: ArticlesController JSON 인증 검증 (회귀 + 신규 테스트)

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`

배경: `ApplicationController#authenticate_user!`가 이미 걸려 있으므로 `:jwt_authenticatable` strategy가 warden에 추가되면서 자동으로 JSON 요청에서 JWT 검증이 동작한다. 별도 컨트롤러 코드 변경 없이 테스트로 동작을 보장한다.

- [ ] **Step 1: Add tests**

`test/controllers/articles_controller_test.rb`의 끝부분(`end` 바로 위)에 추가:

```ruby
  test "JSON index without token returns 401" do
    sign_out users(:john) if @controller.respond_to?(:sign_out)
    get articles_url(format: :json)

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "JSON index with valid JWT returns 200" do
    user = users(:john)
    post user_session_path(format: :json),
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]
    assert token.present?

    get articles_url(format: :json),
        headers: { "Authorization" => token }

    assert_response :success
  end

  test "JSON index with invalid JWT returns 401" do
    get articles_url(format: :json),
        headers: { "Authorization" => "Bearer not-a-real-token" }

    assert_response :unauthorized
  end
```

기존 테스트가 `setup`에서 `sign_in`을 사용 중이라면, 위 401 테스트가 그 효과를 받지 않게 새로운 시나리오는 신규 session 없이 호출해야 한다. 만약 setup에서 자동 sign_in이 일어나면 테스트 내에서 `sign_out users(:john)`을 명시적으로 호출하거나, 새로운 클래스(별도 파일)로 분리하는 것을 고려한다.

- [ ] **Step 2: Run tests**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/articles_controller_test.rb
```

기대: 모든 테스트 통과. 실패 시 setup 패턴을 분석하여 sign_out을 추가하거나 별도 테스트 클래스로 분리.

- [ ] **Step 3: Commit**

```bash
git add test/controllers/articles_controller_test.rb
git commit -m "Test JWT enforcement on Articles JSON endpoints"
```

---

## Task 9: LikesController JSON 인증 테스트

**Files:**
- Modify: `test/controllers/likes_controller_test.rb`

- [ ] **Step 1: Add tests**

`test/controllers/likes_controller_test.rb` 끝부분에 추가:

```ruby
  test "JSON like create without token returns 401" do
    article = articles(:first) rescue Article.first
    skip "no article fixture" unless article

    post article_like_url(article, format: :json), as: :json

    assert_response :unauthorized
  end

  test "JSON like create with valid JWT succeeds" do
    user = users(:john)
    article = Article.first
    skip "no article" unless article

    post user_session_path(format: :json),
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    post article_like_url(article, format: :json),
         headers: { "Authorization" => token },
         as: :json

    assert_includes [ 200, 201 ], response.status
  end
```

기존 테스트의 fixture 이름을 확인 후 `articles(:...)` 부분을 적절히 교체. 사용 가능한 fixture를 모르면 `Article.first`로 대체.

- [ ] **Step 2: Run tests**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/likes_controller_test.rb
```

기대: 모든 테스트 통과.

- [ ] **Step 3: Commit**

```bash
git add test/controllers/likes_controller_test.rb
git commit -m "Test JWT enforcement on Likes JSON endpoints"
```

---

## Task 10: PostsController JSON 인증 테스트

**Files:**
- Modify: `test/controllers/posts_controller_test.rb`

- [ ] **Step 1: Add tests**

`test/controllers/posts_controller_test.rb` 끝부분에 추가:

```ruby
  test "JSON post create without token returns 401" do
    article = Article.first
    skip "no article" unless article

    post article_posts_url(article, format: :json),
         params: { post: { content: "hi" } },
         as: :json

    assert_response :unauthorized
  end

  test "JSON post create with valid JWT succeeds" do
    user = users(:john)
    article = Article.first
    skip "no article" unless article

    post user_session_path(format: :json),
         params: { user: { email: user.email, password: "password" } },
         as: :json
    token = response.headers["Authorization"]

    post article_posts_url(article, format: :json),
         params: { post: { content: "hello via JWT" } },
         headers: { "Authorization" => token },
         as: :json

    assert_includes [ 200, 201, 302 ], response.status
  end
```

- [ ] **Step 2: Run tests**

```bash
eval "$(rbenv init -)" && bin/rails test test/controllers/posts_controller_test.rb
```

기대: 모든 테스트 통과.

- [ ] **Step 3: Commit**

```bash
git add test/controllers/posts_controller_test.rb
git commit -m "Test JWT enforcement on Posts JSON endpoints"
```

---

## Task 11: 전체 테스트 + 검증

**Files:** (없음 — 검증 단계)

- [ ] **Step 1: 전체 테스트 실행**

```bash
eval "$(rbenv init -)" && bin/rails test
```

기대: 전체 통과. 실패 시 원인 분석 후 해당 task 단계로 돌아가 수정.

- [ ] **Step 2: rails_validate**

```bash
eval "$(rbenv init -)" && bin/rails 'ai:tool[validate]' files=app/models/user.rb,app/models/jwt_denylist.rb,app/models/refresh_token.rb,app/controllers/users/sessions_controller.rb,app/controllers/api/v1/auth/tokens_controller.rb,app/lib/json_failure_app.rb level=rails
```

기대: 에러 없음.

- [ ] **Step 3: 라우트 확인**

```bash
eval "$(rbenv init -)" && bin/rails routes | grep -E "(login|logout|api/v1/auth)"
```

기대: `/login`, `/logout`, `/api/v1/auth/refresh` 라우트가 모두 표시됨.

- [ ] **Step 4: 수동 smoke test (선택)**

별도 터미널:

```bash
eval "$(rbenv init -)" && bin/dev
```

다른 터미널:

```bash
# 1. 로그인
curl -i -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"user":{"email":"john@example.com","password":"password"}}'
# → Authorization 헤더와 refresh_token body 확인

# 2. 보호된 엔드포인트
curl -i http://localhost:3000/articles \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <위에서_받은_access>"
# → 200

# 3. 토큰 없이
curl -i http://localhost:3000/articles \
  -H "Accept: application/json"
# → 401 unauthorized

# 4. refresh
curl -i -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<위에서_받은_refresh>"}'
# → 새 access_token + refresh_token

# 5. 로그아웃
curl -i -X DELETE http://localhost:3000/logout \
  -H "Authorization: Bearer <access>"
# → 204
```

- [ ] **Step 5: 최종 commit (변경 없으면 생략)**

전체 테스트 통과 확인 후 변경된 파일이 남아 있다면 commit.

---

## Self-Review Notes

- **Spec coverage**: 모든 spec 항목(devise-jwt, JwtDenylist, RefreshToken, JsonFailureApp, Sessions JSON 응답, Auth::TokensController refresh 회전, Articles/Likes/Posts JWT 보호) 모두 task로 매핑됨.
- **No placeholders**: 모든 단계에 실제 코드, 명령어, 기대 출력 포함.
- **Type consistency**: `JwtDenylist`, `RefreshToken`, `Api::V1::Auth::TokensController`, `JsonFailureApp` 이름이 모든 task에서 일치. `RefreshToken#issue`/`find_active_by_raw`/`revoke!` 시그니처 일관.
- **Namespace 정책**: 신규 엔드포인트(`/api/v1/auth/refresh`)는 namespace 사용, 기존 컨트롤러는 라우트 그대로.
