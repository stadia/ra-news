# Devise Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate from Rails 8.1 built-in authentication to Devise, preserving existing users and Phlex views.

**Architecture:** Install Devise, rename DB columns for compatibility, replace Authentication concern with Devise's Warden-based auth, create custom Devise controllers that render existing Phlex views.

**Tech Stack:** Devise, Warden, Rails 8.1, Phlex, RubyUI, PostgreSQL

**Spec:** `docs/superpowers/specs/2026-03-23-devise-migration-design.md`

---

### Task 1: Install Devise and Generate Configuration

**Files:**
- Modify: `Gemfile`
- Create: `config/initializers/devise.rb` (generated)
- Create: `config/locales/devise.ko.yml`

- [ ] **Step 1: Add devise gem to Gemfile**

```ruby
# In Gemfile, after the bcrypt line:
gem "devise", "~> 4.9"
```

- [ ] **Step 2: Install gems**

Run: `bundle install`

- [ ] **Step 3: Run Devise generator**

Run: `rails generate devise:install`

- [ ] **Step 4: Configure Devise initializer**

In `config/initializers/devise.rb`, set:
```ruby
config.case_insensitive_keys = [:email]
config.strip_whitespace_keys = [:email]
config.mailer_sender = 'noreply@ruby-news.dev'
config.sign_out_via = :get  # Match existing GET /logout
```

- [ ] **Step 5: Create Korean locale file**

Create `config/locales/devise.ko.yml`:
```yaml
ko:
  errors:
    messages:
      not_found: "을(를) 찾을 수 없습니다"
      already_confirmed: "은(는) 이미 인증되었습니다. 로그인해 주세요."
      not_locked: "은(는) 잠겨있지 않습니다"
  devise:
    failure:
      invalid: "이메일 주소나 비밀번호를 다시 확인해 주세요."
      not_found_in_database: "이메일 주소나 비밀번호를 다시 확인해 주세요."
      unauthenticated: "로그인이 필요합니다."
    sessions:
      signed_in: "로그인되었습니다."
      signed_out: "로그아웃되었습니다."
    registrations:
      signed_up: "회원가입이 완료되었습니다."
      updated: "정보가 업데이트되었습니다."
      destroyed: "계정이 삭제되었습니다."
    passwords:
      send_instructions: "비밀번호 재설정 안내를 이메일로 보냈습니다."
      updated: "비밀번호가 변경되었습니다."
```

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock config/initializers/devise.rb config/locales/devise.ko.yml
git commit -m "Install Devise gem and configure initializer with Korean locale"
```

---

### Task 2: Database Migration

**Files:**
- Create: `db/migrate/TIMESTAMP_migrate_to_devise.rb`

- [ ] **Step 1: Generate migration**

Run: `rails generate migration MigrateToDevise`

- [ ] **Step 2: Write migration**

```ruby
class MigrateToDevise < ActiveRecord::Migration[8.1]
  def up
    # Rename columns for Devise compatibility
    rename_column :users, :email_address, :email
    rename_column :users, :password_digest, :encrypted_password

    # Add Devise-specific columns
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime

    # PostgreSQL auto-renames index on column rename, but ensure unique index exists
    unless index_exists?(:users, :email, unique: true)
      add_index :users, :email, unique: true
    end
    add_index :users, :reset_password_token, unique: true

    # Drop sessions table (remove FK first)
    remove_foreign_key :sessions, :users if foreign_key_exists?(:sessions, :users)
    drop_table :sessions
  end

  def down
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    remove_index :users, :reset_password_token

    remove_column :users, :remember_created_at
    remove_column :users, :reset_password_sent_at
    remove_column :users, :reset_password_token

    rename_column :users, :encrypted_password, :password_digest
    rename_column :users, :email, :email_address
  end
end
```

- [ ] **Step 3: Run migration**

Run: `rails db:migrate`

- [ ] **Step 4: Commit**

```bash
git add db/
git commit -m "Migrate database schema from built-in auth to Devise"
```

---

### Task 3: Update User Model

**Files:**
- Modify: `app/models/user.rb`
- Delete: `app/models/session.rb`
- Delete: `app/models/current.rb`

- [ ] **Step 1: Update User model**

Replace `app/models/user.rb` with:
```ruby
# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :rememberable

  acts_as_liker
  has_many :push_subscriptions, dependent: :destroy
  has_many :articles, dependent: :nullify
  has_many :posts, dependent: :destroy

  # Name validations (email/password handled by Devise validatable)
  validates :name, presence: true,
                   length: { minimum: 2, maximum: 50 },
                   format: {
                     with: /\A[가-힣a-zA-Z\s]+\z/,
                     message: "한글, 영문, 공백만 사용할 수 있습니다"
                   }

  # Keep email normalizer — Devise only normalizes at auth time, not on save
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  include Federails::ActorEntity
  acts_as_federails_actor username_field: :username, name_field: :name, profile_url_method: :user_profile_url

  after_followed :accept_follow

  scope :with_role, ->(role_name) do
    where("? = ANY (roles)", role_name.to_s)
  end
  scope :admins, -> { with_role(:admin) }

  def admin?
    has_role?(:admin)
  end

  def full_name
    name.presence || email.split("@").first
  end

  def has_role?(role_name)
    roles.include? role_name.to_s
  end

  def roles=(role_names)
    self[:roles] = role_names.is_a?(Array) ? role_names.uniq : role_names.split(" ").uniq
  end

  def accept_follow(following)
    following.accept! if has_role?(:bot) && following.respond_to?(:accept!)
  end

  def self.first_bot
    with_role("bot").first
  end
end
```

- [ ] **Step 2: Delete Session model**

Run: `rm app/models/session.rb`

- [ ] **Step 3: Delete Current model**

Run: `rm app/models/current.rb`

- [ ] **Step 4: Commit**

```bash
git add app/models/user.rb
git rm app/models/session.rb app/models/current.rb
git commit -m "Update User model for Devise, remove Session and Current models"
```

---

### Task 4: Update Fixtures and Seeds

**Files:**
- Modify: `test/fixtures/users.yml`
- Delete: `test/fixtures/sessions.yml` (if exists)
- Modify: `db/seeds.rb`

- [ ] **Step 1: Update fixtures**

In `test/fixtures/users.yml`, replace all `email_address:` with `email:` and `password_digest:` with `encrypted_password:`:

```yaml
# frozen_string_literal: true

<% encrypted_password = BCrypt::Password.create("password") %>
<% admin_encrypted_password = BCrypt::Password.create("admin_password") %>

john:
  email: john@example.com
  name: 존 도
  username: john
  encrypted_password: <%= encrypted_password %>
  roles:
    - user
    - editor
    - bot

jane:
  email: jane@example.com
  name: 제인 스미스
  username: jane
  encrypted_password: <%= encrypted_password %>
  roles:
    - user
    - bot

admin:
  email: admin@example.com
  name: 관리자
  username: admin
  encrypted_password: <%= admin_encrypted_password %>
  roles:
    - user
    - admin

korean_user:
  email: korean@example.com
  name: 김철수
  username: korean_user
  encrypted_password: <%= encrypted_password %>
  roles:
    - user
    - bot

user_with_spaces:
  email: spaces@example.com
  name: 홍 길 동
  username: user_with_spaces
  encrypted_password: <%= encrypted_password %>
  roles:
    - user

minimal_user:
  email: minimal@example.com
  name: 최소
  username: minimal_user
  encrypted_password: <%= encrypted_password %>
  roles:
    - user

one:
  email: one@example.com
  name: 사용자 일
  username: user_one
  encrypted_password: <%= encrypted_password %>
  roles:
    - user

two:
  email: two@example.com
  name: 사용자 이
  username: user_two
  encrypted_password: <%= encrypted_password %>
  roles:
    - user
```

- [ ] **Step 2: Delete sessions fixtures if exists**

Run: `rm -f test/fixtures/sessions.yml`

- [ ] **Step 3: Update seeds**

In `db/seeds.rb`, change `email_address` to `email`:
```ruby
admin = User.find_or_initialize_by(email: "admin@example.com") do |user|
```

- [ ] **Step 4: Commit**

```bash
git add test/fixtures/users.yml db/seeds.rb
git rm -f test/fixtures/sessions.yml
git commit -m "Update fixtures and seeds for Devise column names"
```

---

### Task 5: Replace Authentication Concern Usage in ALL Controllers

> **CRITICAL:** This must be done BEFORE deleting the Authentication concern in Task 8. Every controller that calls `allow_unauthenticated_access` or `require_authentication` must be updated.

**Files:**
- Modify: `app/controllers/application_controller.rb`
- Modify: `app/controllers/home_controller.rb`
- Modify: `app/controllers/articles_controller.rb`
- Modify: `app/controllers/profiles_controller.rb`
- Modify: `app/controllers/actors_controller.rb`
- Modify: `app/controllers/comments_controller.rb`
- Modify: `app/controllers/posts_controller.rb`
- Modify: `app/controllers/activities_controller.rb`
- Modify: `app/controllers/likes_controller.rb`
- Modify: `app/controllers/followings_controller.rb`
- Modify: `app/controllers/push_subscriptions_controller.rb`
- Modify: `app/controllers/federails/application_controller.rb`
- Modify: `app/controllers/madmin/application_controller.rb`
- Modify: `app/constraints/authenticated_constraint.rb`
- Modify: `app/controllers/concerns/rate_limiting.rb`

- [ ] **Step 1: Update ApplicationController**

Remove `include Authentication`. Devise adds `authenticate_user!` and `current_user` automatically. Add `before_action :authenticate_user!` as default (Devise doesn't auto-add this like the old concern did).

```ruby
# frozen_string_literal: true

require "schema_dot_org/web_site"

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  allow_browser versions: { ie: false }
  layout -> { request.format.turbo_stream? ? false : Components::Layout }

  before_action do
    Honeybadger.context({
      user_id: current_user&.id
    })

    if request.path == "/"
      @web_site = SchemaDotOrg::WebSite.new(
        name: "Ruby-News | 루비 AI 뉴스",
        url:  "https://ruby-news.kr",
        potential_action: SchemaDotOrg::SearchAction.new(
          target: "https://ruby-news.kr/articles?search={search_term_string}",
          query_input: "required name=search_term_string"
        )
      )
    end
  end

  unless Rails.env.production?
    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end

  private

  def cacheable_page!(max_age: 5.minutes)
    return if user_signed_in?
    request.session_options[:skip] = true
    expires_in max_age, public: true
  end
end
```

- [ ] **Step 2: Replace `allow_unauthenticated_access` in all controllers**

Pattern: `allow_unauthenticated_access` → `skip_before_action :authenticate_user!`

Controllers to update:
- `home_controller.rb`: `skip_before_action :authenticate_user!` (was `allow_unauthenticated_access`)
- `articles_controller.rb`: `skip_before_action :authenticate_user!, only: %i[index show others tag]`
- `profiles_controller.rb`: `skip_before_action :authenticate_user!`
- `actors_controller.rb`: `skip_before_action :authenticate_user!`

- [ ] **Step 3: Replace `require_authentication` in all controllers**

Pattern: `before_action :require_authentication` → `before_action :authenticate_user!`

Controllers to update:
- `comments_controller.rb`: `before_action :authenticate_user!, only: %i[create destroy]`
- `posts_controller.rb`: `before_action :authenticate_user!, only: [:create]`
- `activities_controller.rb`: `before_action :authenticate_user!, only: [:feed]`
- `likes_controller.rb`: `before_action :authenticate_user!`
- `followings_controller.rb`: `before_action :authenticate_user!`

- [ ] **Step 4: Replace `Current.user` with `current_user` in all controllers**

In every controller: `Current.user` → `current_user`

Files: `followings_controller.rb`, `posts_controller.rb`, `activities_controller.rb`, `push_subscriptions_controller.rb`, `home_controller.rb`, `articles_controller.rb`, `comments_controller.rb`, `likes_controller.rb`, `actors_controller.rb`, `federails/application_controller.rb`

For `push_subscriptions_controller.rb`, also replace `Current.user.nil?` → `current_user.nil?`.

- [ ] **Step 5: Update AuthenticatedConstraint**

Replace `app/constraints/authenticated_constraint.rb`:
```ruby
# frozen_string_literal: true

class AuthenticatedConstraint
  def matches?(request)
    warden = request.env['warden']
    warden&.authenticated?(:user) && warden.user(:user)&.admin? || false
  end
end
```

- [ ] **Step 6: Update Madmin controller**

Replace `app/controllers/madmin/application_controller.rb`:
```ruby
module Madmin
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers

    before_action :authenticate_admin_user

    def authenticate_admin_user
      authenticate_user!
      redirect_to "/", status: :forbidden unless current_user&.admin?
    end
  end
end
```

- [ ] **Step 7: Update RateLimiting concern**

In `app/controllers/concerns/rate_limiting.rb`:
```ruby
def check_rate_limit
  user = current_user if respond_to?(:current_user) && current_user
  return if user&.admin?
  # ... rest unchanged
end
```

- [ ] **Step 8: Replace `Current.user` and `authenticated?` in view components**

In `app/components/comments/comment.rb`:
- `Current.user` → `view_context.current_user`
- `view_context.authenticated?` → `view_context.user_signed_in?`

In `app/components/comments/comment_form.rb` and `app/components/comments/comment_reply_form.rb`:
- `view_context.authenticated?` → `view_context.user_signed_in?`

In `app/components/likes/button.rb`:
- `Current.user` → `view_context.current_user`

In `app/components/layout.rb`:
- `vc.authenticated?` → `vc.user_signed_in?`
- `Current.user` → `vc.current_user`

In `app/views/profiles/show.rb` and `app/views/profiles/follow_list.rb`:
- `Current.user` → `view_context.current_user`

In `app/views/followings/follow_actions.rb`:
- `Current.user` → `view_context.current_user`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Replace Authentication concern usage with Devise helpers across all controllers and views"
```

---

### Task 6: Create Devise Custom Controllers

**Files:**
- Create: `app/controllers/users/sessions_controller.rb`
- Create: `app/controllers/users/registrations_controller.rb`
- Create: `app/controllers/users/passwords_controller.rb`

- [ ] **Step 1: Create sessions controller**

Create `app/controllers/users/sessions_controller.rb`:
```ruby
# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout -> { Components::Layout }

  def new
    redirect_to root_url and return if user_signed_in?
    render Views::Sessions::New.new
  end

  def create
    super
  end

  def destroy
    super
  end
end
```

- [ ] **Step 2: Create registrations controller**

Create `app/controllers/users/registrations_controller.rb`:
```ruby
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout -> { Components::Layout }

  def new
    build_resource
    render Views::Users::New.new(user: resource)
  end

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      set_flash_message! :notice, :signed_up
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      render Views::Users::New.new(user: resource), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Users::Edit.new(user: resource)
  end

  # Password change page (custom action)
  def password
    render Views::Users::Password.new(user: resource)
  end

  def update
    if updating_password?
      update_user_password
    else
      update_without_password
    end
  end

  def destroy
    resource.destroy!
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    redirect_to root_path, status: :see_other, notice: "계정이 삭제되었습니다."
  end

  protected

  def after_sign_up_path_for(_resource)
    root_path
  end

  def sign_up_params
    params.expect(user: [:email, :name, :password, :password_confirmation])
  end

  def account_update_params
    params.expect(user: [:email, :name])
  end

  private

  def updating_password?
    user = params[:user]
    return false unless user.respond_to?(:key?)
    user.key?(:password) || user.key?(:password_confirmation) ||
      user.key?("password") || user.key?("password_confirmation")
  end

  def update_user_password
    password_params = params.expect(user: [:current_password, :password, :password_confirmation])
    if resource.update_with_password(password_params)
      bypass_sign_in resource
      redirect_to edit_user_registration_path, notice: t("devise.registrations.updated")
    else
      render Views::Users::Password.new(user: resource), status: :unprocessable_entity
    end
  end

  def update_without_password
    if resource.update(account_update_params)
      redirect_to edit_user_registration_path, notice: t("devise.registrations.updated")
    else
      render Views::Users::Edit.new(user: resource), status: :unprocessable_entity
    end
  end
end
```

- [ ] **Step 3: Create passwords controller**

Create `app/controllers/users/passwords_controller.rb`:
```ruby
# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout -> { Components::Layout }

  def new
    render Views::Passwords::New.new
  end

  def edit
    render Views::Passwords::Edit.new(token: params[:reset_password_token])
  end
end
```

- [ ] **Step 4: Commit**

```bash
git add app/controllers/users/
git commit -m "Create custom Devise controllers with Phlex view rendering"
```

---

### Task 7: Update Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Replace auth routes with Devise routes**

In `config/routes.rb`:

Remove these lines:
```ruby
resources :passwords, param: :token
```
```ruby
resource :users, path: :account do
  member do
    get :password
  end
end
```
```ruby
get "login" => "sessions#new", as: :new_session
post "login" => "sessions#create", as: :session
get "logout" => "sessions#destroy", as: :logout
get "signup" => "users#new", as: :new_user
post "signup" => "users#create", as: :user
```

Add near the top (after `draw :madmin`):
```ruby
devise_for :users, path: '', path_names: {
  sign_in: 'login', sign_out: 'logout', sign_up: 'signup',
  password: 'passwords', registration: 'account'
}, controllers: {
  sessions: 'users/sessions',
  registrations: 'users/registrations',
  passwords: 'users/passwords'
}

# Custom password change page (inside account)
devise_scope :user do
  get 'account/password', to: 'users/registrations#password', as: :account_password
end
```

- [ ] **Step 2: Verify routes**

Run: `rails routes | grep -E 'login|logout|signup|account|password'`

Expected: Devise-generated routes for login, logout, signup, account, and password reset.

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "Replace manual auth routes with devise_for"
```

---

### Task 8: Remove Old Auth Code

> **IMPORTANT:** Only safe to do now because Task 5 already replaced all references.

**Files:**
- Delete: `app/controllers/sessions_controller.rb`
- Delete: `app/controllers/passwords_controller.rb`
- Delete: `app/controllers/users_controller.rb`
- Delete: `app/controllers/concerns/authentication.rb`
- Delete: `app/mailers/passwords_mailer.rb`
- Delete: `app/views/passwords_mailer/` (entire directory including .html.erb and .text.erb)

- [ ] **Step 1: Remove old controllers and concern**

```bash
rm app/controllers/sessions_controller.rb
rm app/controllers/passwords_controller.rb
rm app/controllers/users_controller.rb
rm app/controllers/concerns/authentication.rb
rm app/mailers/passwords_mailer.rb
rm -rf app/views/passwords_mailer
```

- [ ] **Step 2: Commit**

```bash
git rm app/controllers/sessions_controller.rb app/controllers/passwords_controller.rb app/controllers/users_controller.rb app/controllers/concerns/authentication.rb app/mailers/passwords_mailer.rb
git rm -r app/views/passwords_mailer
git commit -m "Remove old authentication controllers, concern, and mailer"
```

---

### Task 9: Global `email_address` → `email` Replacement and View URL Updates

**Files:**
- Modify: `app/views/sessions/new.rb`
- Modify: `app/views/passwords/new.rb`
- Modify: `app/views/passwords/edit.rb`
- Modify: `app/views/users/new.rb`
- Modify: `app/components/users/form.rb`
- Modify: `app/components/users/pwd_form.rb`
- Modify: `app/components/users/user.rb`
- Modify: `app/madmin/resources/user_resource.rb`

- [ ] **Step 1: Update sessions/new.rb**

- `:email_address` → `:email`
- `params[:email_address]` → `params[:email]`
- `for: :email_address` → `for: :email`
- `form_with(url: session_url` → `form_with(url: user_session_path`
- `new_user_path` → `new_user_registration_path`

- [ ] **Step 2: Update passwords/new.rb**

- `:email_address` → `:email`
- `request.params[:email_address]` → `request.params[:email]`
- `for: :email_address` → `for: :email`
- `passwords_path` → `user_password_path`

- [ ] **Step 3: Update passwords/edit.rb**

- `password_path(@token)` → `user_password_path`
- Add `method: :put` if not present
- Add hidden field: `f.hidden_field :reset_password_token, value: @token`

- [ ] **Step 4: Update users/new.rb**

- `new_session_path` → `new_user_session_path`

- [ ] **Step 5: Update components/users/form.rb**

- `@user.email_address_was` → `@user.email_was`
- `form.email_field :email_address` → `form.email_field :email`
- `@user.errors[:email_address]` → `@user.errors[:email]`
- `for: :user_email_address` → `for: :user_email`
- `@user.email_address.presence` → `@user.email.presence`
- `url: users_path` → `url: user_registration_path`
- Back link `users_path` → `edit_user_registration_path`

- [ ] **Step 6: Update components/users/pwd_form.rb**

- `@user.email_address` → `@user.email`
- `@user.email_address.presence` → `@user.email.presence`
- `url: users_path` → `url: user_registration_path`
- Back link `users_path` → `edit_user_registration_path`
- Add `current_password` field before password fields:

```ruby
render RubyUI::FormField.new do
  render RubyUI::FormFieldLabel.new(for: :user_current_password) { "현재 비밀번호" }
  form.password_field :current_password, class: input_classes(@user.errors[:current_password]), placeholder: "••••••••"
  @user.errors[:current_password].each do |msg|
    render RubyUI::FormFieldError.new { msg }
  end
end
```

- [ ] **Step 7: Update components/users/user.rb**

- `@user.email_address` → `@user.email`

- [ ] **Step 8: Update Madmin resource**

In `app/madmin/resources/user_resource.rb`: `attribute :email_address` → `attribute :email`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Replace email_address with email and update view URLs for Devise"
```

---

### Task 10: Update Tests

**Files:**
- Modify: `test/models/user_test.rb`
- Delete: `test/models/current_test.rb`
- Delete: `test/models/session_test.rb`
- Modify: `test/test_helper.rb`
- Modify: `test/controllers/posts_controller_test.rb`

- [ ] **Step 1: Update test_helper.rb**

Replace the `sign_in_as` method:
```ruby
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_as(user)
    sign_in user
  end
end
```

- [ ] **Step 2: Update user_test.rb**

Replace all `email_address` → `email` throughout the file. Replace `User.authenticate_by` calls with `user.valid_password?`. Remove references to `has_secure_password` specific behavior.

- [ ] **Step 3: Delete obsolete tests**

```bash
rm test/models/current_test.rb
rm test/models/session_test.rb
```

- [ ] **Step 4: Update posts_controller_test.rb**

Replace `post session_url, params: { email_address: @user.email_address, password: "password" }` → use Devise test helper `sign_in @user`.

- [ ] **Step 5: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Update test suite for Devise authentication"
```

---

### Task 11: Verify and Clean Up

- [ ] **Step 1: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass

- [ ] **Step 2: Verify bcrypt compatibility**

Run: `rails runner "u = User.first; puts u.valid_password?('password')"`
Expected: `true`

- [ ] **Step 3: Search for any remaining references**

Run: `grep -r "Current\.user\|Current\.session\|email_address\|authenticated?\|Authentication\|allow_unauthenticated_access\|require_authentication" app/ --include="*.rb" -l`
Expected: No matches

- [ ] **Step 4: Remove bcrypt from Gemfile**

Devise depends on bcrypt, so the explicit `gem "bcrypt"` line in Gemfile can be removed.

Run: `bundle install` to verify.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Clean up remaining references and verify Devise migration"
```

---

### Task 12: Remove Obsolete RBS Type Signatures

**Files:**
- Delete/update files in `sig/` directory:
  - `sig/generated/models/current.rbs` (delete)
  - `sig/generated/models/session.rbs` (delete)
  - `sig/rbs_rails/app/models/session.rbs` (delete)
  - `sig/generated/controllers/concerns/authentication.rbs` (delete)
  - `sig/generated/controllers/sessions_controller.rbs` (delete)
  - `sig/generated/controllers/passwords_controller.rbs` (delete)
  - `sig/generated/controllers/users_controller.rbs` (delete)
  - `sig/generated/mailers/passwords_mailer.rbs` (delete)
  - `sig/generated/constraints/authenticated_constraint.rbs` (update for Warden-based version)

- [ ] **Step 1: Check which RBS files exist**

Run: `find sig/ -name "*.rbs" | xargs grep -l "Session\|Current\|Authentication\|PasswordsMailer\|SessionsController\|PasswordsController\|UsersController" 2>/dev/null`

- [ ] **Step 2: Remove obsolete RBS files**

Delete all matching files.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Remove obsolete RBS type signatures for deleted auth code"
```

---

### Task 13: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Update authentication section**

Find the line about authentication using `Current.user` pattern and update to reflect Devise:

Replace references to "custom auth and `Current.user` pattern, not Devise" with:
"Authentication uses Devise gem with custom controllers for Phlex views. Use `current_user` helper (not `Current.user`). Devise modules: database_authenticatable, registerable, recoverable, validatable, rememberable."

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "Update AGENTS.md authentication documentation for Devise"
```

---

### Task 14: Manual Smoke Test

- [ ] **Step 1: Start server**

Run: `bin/rails server`

- [ ] **Step 2: Test all auth flows**

- Login at `/login` with existing credentials
- Signup at `/signup` with new user
- Password reset at `/passwords/new` — request reset email
- Logout at `/logout`
- Account edit at `/account/edit`
- Password change at `/account/password` — requires current password
- Admin routes (`/jobs`, `/pg_reports`) — should require admin login
- Public profiles (`/@username`) — should work without login
