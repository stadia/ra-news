# Federails Client 교체 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Federails 엔진의 client 컨트롤러/뷰를 비활성화하고, 앱 자체 컨트롤러 + Phlex 뷰 + Turbo Stream으로 대체한다.

**Architecture:** `client_routes_path: nil`로 엔진 client 라우트를 비활성화. 앱에 FollowingsController, ActorsController, ActivitiesController(stub)를 새로 만들고, 뷰는 Phlex로 구현. mutation 액션에 turbo_stream 응답 추가.

**Tech Stack:** Rails, Phlex 2.4, Turbo Stream, Pundit, Minitest, Federails 엔진 모델 재사용

**Spec:** `docs/superpowers/specs/2026-03-19-federails-client-replacement-design.md`

---

## File Structure

### 생성할 파일

| 파일 | 역할 |
|---|---|
| `app/controllers/followings_controller.rb` | 팔로우 CRUD + turbo_stream |
| `app/controllers/actors_controller.rb` | actor show/lookup stub |
| `app/controllers/activities_controller.rb` | activities stub (ERB 위임) |
| `app/views/followings/follow_actions.rb` | FollowActions Phlex 컴포넌트 |
| `app/views/actors/show.rb` | Actor 상세 Phlex 뷰 |
| `app/views/actors/gone.rb` | Tombstoned actor Phlex 뷰 |
| `test/controllers/followings_controller_test.rb` | FollowingsController 테스트 |
| `test/controllers/actors_controller_test.rb` | ActorsController 테스트 |
| `test/controllers/activities_controller_test.rb` | ActivitiesController 테스트 |
| `test/fixtures/federails_followings.yml` | Following 테스트 픽스처 |

### 수정할 파일

| 파일 | 변경 내용 |
|---|---|
| `config/federails.yml` | `client_routes_path: null` |
| `config/initializers/federails.rb` | `remote_follow_url_method` 설정 |
| `config/routes.rb` | 새 라우트 추가 |
| `app/views/layouts/federails/application.html.erb` | 라우트 헬퍼 변경 |
| `app/views/federails/client/common/_client_links.html.erb` | 라우트 헬퍼 변경 |
| `app/views/federails/client/actors/_lookup_form.html.erb` | 라우트 헬퍼 변경 |
| `app/views/federails/client/activities/_activity.html.erb` | 라우트 헬퍼 변경 |

### 삭제할 파일

| 파일 | 사유 |
|---|---|
| `app/views/federails/client/actors/show.html.erb` | Phlex 전환 |
| `app/views/federails/client/actors/gone.html.erb` | Phlex 전환 |
| `app/views/federails/client/followings/_follow_actions.html.erb` | Phlex 전환 |
| `app/views/federails/client/followings/_follow.html.erb` | Phlex 전환 |
| `app/views/federails/client/followings/_follower.html.erb` | Phlex 전환 |
| `app/views/federails/client/followings/_form.html.erb` | 미사용 |
| `app/views/federails/client/followings/index.html.erb` | 미사용 |
| `app/views/federails/client/followings/show.html.erb` | 미사용 |
| `app/views/federails/client/followings/*.json.jbuilder` | 미사용 |
| `app/views/federails/client/actors/index.html.erb` | actors index 제외 |

---

### Task 1: 설정 변경 및 라우트 추가

**Files:**
- Modify: `config/federails.yml:11` — `client_routes_path: null`
- Modify: `config/initializers/federails.rb` — `remote_follow_url_method` 추가
- Modify: `config/routes.rb` — 새 라우트 추가

- [ ] **Step 1: `config/federails.yml` 수정**

```yaml
# client_routes_path: app  ← 기존
client_routes_path: null
```

모든 환경(defaults)에 적용.

- [ ] **Step 2: `config/initializers/federails.rb` 수정**

```ruby
Federails.config_from "federails"

Federails.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end

Rails.application.config.after_initialize do
  Federails::ServerController.class_eval do
    private

    def current_user
      nil
    end
  end
end
```

- [ ] **Step 3: `config/routes.rb`에 라우트 추가**

`mount Federails::Engine => "/"` 위에 추가:

```ruby
# Federails client 대체 라우트
resources :followings, only: [:new, :create, :destroy] do
  collection do
    post :follow
  end
  member do
    put :accept
  end
end

resources :actors, only: [:show] do
  collection do
    get :lookup
  end
end

resources :activities, only: [:index] do
  collection do
    get :feed
  end
end
resources :actors, only: [] do
  resources :activities, only: [:index]
end
```

- [ ] **Step 4: 라우트 확인**

Run: `bin/rails routes | grep -E "following|actor|activit" | head -20`
Expected: `followings#create`, `followings#follow`, `followings#accept`, `followings#destroy`, `actors#show`, `actors#lookup`, `activities#index`, `activities#feed` 라우트 출력

- [ ] **Step 5: 커밋**

```bash
git add config/federails.yml config/initializers/federails.rb config/routes.rb
git commit -m "feat: Federails client 라우트 비활성화 및 앱 라우트 추가"
```

---

### Task 2: 테스트 인증 헬퍼 + ActivitiesController stub 생성

**Files:**
- Modify: `test/test_helper.rb` — `sign_in_as` 헬퍼 추가
- Create: `app/controllers/activities_controller.rb`
- Modify: `app/views/federails/client/activities/_activity.html.erb` — 헬퍼 변경
- Create: `test/controllers/activities_controller_test.rb`

- [ ] **Step 1: 테스트 헬퍼에 `sign_in_as` 추가**

`test/test_helper.rb`의 `ActiveSupport::TestCase` 블록에 추가:

```ruby
# 인증이 필요한 통합 테스트에서 사용.
# signed cookie를 설정하여 세션을 시작한다.
def sign_in_as(user)
  session = user.sessions.first || user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
  post session_path, params: { email_address: user.email_address, password: "password" }
  session
end
```

**참고**: 앱은 `cookies.signed[:session_id]`를 사용하므로 raw Cookie 헤더로는 인증이 불가. `sign_in_as`로 실제 로그인 흐름을 거쳐야 한다.

- [ ] **Step 2: 테스트 작성**

```ruby
# test/controllers/activities_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "GET index requires authentication" do
    get activities_path
    assert_redirected_to new_session_path
  end

  test "GET index returns 200 for authenticated user" do
    sign_in_as(@user)
    get activities_path
    assert_response :success
  end

  test "GET feed requires authentication" do
    get feed_activities_path
    assert_redirected_to new_session_path
  end

  test "GET feed returns 200 for authenticated user" do
    sign_in_as(@user)
    get feed_activities_path
    assert_response :success
  end

  test "GET actor activities returns 200" do
    sign_in_as(@user)
    actor = federails_actors(:john_actor)
    get actor_activities_path(actor)
    assert_response :success
  end
end
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `bin/rails test test/controllers/activities_controller_test.rb`
Expected: FAIL — ActivitiesController 없음

- [ ] **Step 3: `_activity.html.erb` 헬퍼 변경**

`app/views/federails/client/activities/_activity.html.erb`에서:

```
federails.client_actor_url(activity.actor)
```
→
```
actor_url(activity.actor)
```

- [ ] **Step 4: ActivitiesController 구현**

```ruby
# app/controllers/activities_controller.rb
# frozen_string_literal: true

class ActivitiesController < ApplicationController
  include Pundit::Authorization

  after_action :verify_authorized

  def index
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = policy_scope(Federails::Activity, policy_scope_class: Federails::Client::ActivityPolicy::Scope).all
    @activities = @activities.where(actor: Federails::Actor.find_param(params[:actor_id])) if params[:actor_id]
    render template: "federails/client/activities/index"
  end

  def feed
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    @activities = Federails::Activity.feed_for(Current.user.federails_actor)
    render template: "federails/client/activities/feed"
  end
end
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `bin/rails test test/controllers/activities_controller_test.rb`
Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add app/controllers/activities_controller.rb test/controllers/activities_controller_test.rb app/views/federails/client/activities/_activity.html.erb
git commit -m "feat: ActivitiesController stub 추가 (기존 ERB 위임)"
```

---

### Task 3: FollowActions Phlex 컴포넌트 생성

**Files:**
- Create: `app/views/followings/follow_actions.rb`

- [ ] **Step 1: `Views::Followings::FollowActions` Phlex 컴포넌트 생성**

```ruby
# app/views/followings/follow_actions.rb
# frozen_string_literal: true

class Views::Followings::FollowActions < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    current = Current.user
    policy = Federails::Client::FollowingPolicy.new(current, Federails::Following)

    div(id: "follow_actions_#{@actor.id}", class: "flex flex-wrap items-center gap-3 mt-2") do
      if policy.create?
        authenticated_actions(current)
      elsif current.nil?
        logged_out_message
      end
    end
  end

  private

  def authenticated_actions(current)
    follow = current.federails_actor.follows?(@actor)

    if @actor.entity == current
      span(class: "text-slate-400 text-sm") { "내 계정입니다." }
    elsif follow
      existing_follow(follow)
    else
      new_follow
    end

    incoming_follow_request(current)
  end

  def existing_follow(follow)
    span(class: "text-slate-400 text-sm") { "팔로우 중 (#{follow.status})" }
    button_to "팔로우 취소",
      following_path(follow),
      method: :delete,
      class: "px-4 py-2 text-sm font-medium bg-slate-700 hover:bg-slate-600 text-slate-200 rounded-lg border border-slate-600 transition-colors cursor-pointer"
  end

  def new_follow
    button_to "Follow @#{@actor.username}",
      follow_followings_path,
      params: { account: @actor.at_address },
      method: :post,
      class: "px-4 py-2 text-sm font-medium bg-green-600 hover:bg-green-500 text-white rounded-lg transition-colors cursor-pointer"
  end

  def incoming_follow_request(current)
    followed = @actor.follows?(current.federails_actor)
    return unless followed

    if followed.pending?
      span(class: "text-slate-400 text-sm") { "#{@actor.username}이(가) 팔로우 요청했습니다." }
      button_to "수락",
        accept_following_path(followed),
        method: :put,
        class: "px-4 py-2 text-sm font-medium bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-colors cursor-pointer"
    else
      span(class: "text-slate-400 text-sm") { "#{@actor.username}이(가) 팔로우 중입니다." }
    end
  end

  def logged_out_message
    p(class: "text-slate-400 text-sm") do
      plain "팔로우하려면 로그인하세요. 또는 다른 Fediverse 서버에서 검색: "
      code(class: "ml-1 bg-slate-800 px-1.5 py-0.5 rounded text-slate-300 text-xs") do
        plain @actor.at_address(prefix: "")
      end
    end
  end
end
```

- [ ] **Step 2: 커밋**

```bash
git add app/views/followings/follow_actions.rb
git commit -m "feat: FollowActions Phlex 컴포넌트 추가"
```

---

### Task 4: ActorsController 및 Phlex 뷰 생성

**Files:**
- Create: `app/controllers/actors_controller.rb`
- Create: `app/views/actors/show.rb`
- Create: `app/views/actors/gone.rb`
- Create: `test/controllers/actors_controller_test.rb`

- [ ] **Step 1: 테스트 작성**

```ruby
# test/controllers/actors_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ActorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @actor = federails_actors(:john_actor)
  end

  test "GET show returns 200" do
    get actor_path(@actor)
    assert_response :success
  end

  test "GET show returns JSON" do
    get actor_path(@actor), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("username")
  end

  test "GET show returns 410 for tombstoned actor" do
    @actor.update!(tombstoned: true)
    get actor_path(@actor)
    assert_response :gone
  end

  test "GET show returns 410 JSON for tombstoned actor" do
    @actor.update!(tombstoned: true)
    get actor_path(@actor), as: :json
    assert_response :gone
    json = JSON.parse(response.body)
    assert_equal "Gone", json["error"]
  end

  test "GET lookup finds actor by account" do
    get lookup_actors_path(account: @actor.at_address)
    assert_response :success
  end
end
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `bin/rails test test/controllers/actors_controller_test.rb`
Expected: FAIL — ActorsController 없음

- [ ] **Step 3: `Views::Actors::Gone` Phlex 컴포넌트 생성**

```ruby
# app/views/actors/gone.rb
# frozen_string_literal: true

class Views::Actors::Gone < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def view_template
    content_for :title, "Gone"

    div(class: "max-w-2xl mx-auto py-16 px-4 text-center") do
      render RubyUI::Heading.new(level: 1) { "410 Gone" }
      p(class: "text-slate-400 mt-4") { "이 계정은 더 이상 존재하지 않습니다." }
    end
  end
end
```

- [ ] **Step 4: `Views::Actors::Show` Phlex 컴포넌트 생성**

기존 `federails/client/actors/show.html.erb`를 Phlex로 전환. `Views::Followings::FollowActions`를 사용 (Task 3에서 생성됨).

```ruby
# app/views/actors/show.rb
# frozen_string_literal: true

class Views::Actors::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  def initialize(actor:)
    @actor = actor
  end

  def view_template
    content_for :title, @actor.name

    render RubyUI::Heading.new(level: 1) { @actor.name }

    section do
      render Views::Followings::FollowActions.new(actor: @actor)
    end

    section do
      if @actor.local?
        link_to "All activities", actor_activities_path(@actor)
      elsif @actor.profile_url
        link_to "Visit profile", @actor.profile_url
      end
    end

    actor_details
    follows_section
    followers_section
    recent_activities
  end

  private

  def actor_details
    section do
      render RubyUI::Heading.new(level: 2) { "Actor details" }

      detail("Federated url", @actor.federated_url)
      detail("Username", @actor.username)
      detail("Inbox URL", @actor.inbox_url)
      detail("Outbox URL", @actor.outbox_url)
      detail("Followers URL", @actor.followers_url)
      detail("Followings URL", @actor.followings_url)

      p do
        b { "Profile url: " }
        link_to("Profile", @actor.profile_url) if @actor.profile_url
      end

      p do
        b { "Federation address: " }
        plain @actor.at_address
      end

      p do
        if @actor.local? && @actor.entity_configuration[:profile_url_method]
          b { "Home page: " }
          link_to @actor.entity.send(@actor.entity_configuration[:username_field]),
                  Rails.application.routes.url_helpers.send(@actor.entity_configuration[:profile_url_method], @actor.entity)
        elsif @actor.profile_url
          b { "Federation profile URL (JSON): " }
          link_to @actor.name, @actor.profile_url
        else
          plain "(No homepage)"
        end
      end
    end
  end

  def follows_section
    hr

    section do
      render RubyUI::Heading.new(level: 2) { "Follows (Who is followed?)" }

      if @actor.following_follows.empty?
        p { "#{@actor.username} follows nothing" }
      end

      @actor.following_follows.each do |following|
        follow_row(following.target_actor)
      end
    end
  end

  def followers_section
    section do
      render RubyUI::Heading.new(level: 2) { "Followers (Who follows?)" }

      if @actor.following_followers.empty?
        p { "Nothing follows #{@actor.username}" }
      end

      @actor.following_followers.each do |following|
        follower_row(following)
      end
    end
  end

  def recent_activities
    section do
      render RubyUI::Heading.new(level: 2) { "10 last activities" }

      activities = @actor.activities.last(10)
      if activities.empty?
        p { "No activity to display" }
      end

      activities.each do |activity|
        render "federails/client/activities/activity", activity: activity
      end
    end
  end

  def follow_row(target_actor)
    div do
      b { link_to target_actor.name, actor_url(target_actor) }
      plain " (#{target_actor.at_address})"
    end
  end

  def follower_row(following)
    div do
      b { link_to following.actor.name, actor_url(following.actor) }
      plain " (#{following.actor.at_address}) (#{following.status})"
      if following.pending? && following.target_actor == Current.user&.federails_actor
        whitespace
        plain "Accept 버튼은 FollowActions 컴포넌트 참조"
      end
    end
  end

  def detail(label, value)
    p do
      b { "#{label}: " }
      plain value.to_s
    end
  end
end
```

- [ ] **Step 5: ActorsController 구현**

```ruby
# app/controllers/actors_controller.rb
# frozen_string_literal: true

class ActorsController < ApplicationController
  include Pundit::Authorization

  allow_unauthenticated_access
  before_action :resume_session
  after_action :verify_authorized

  def show
    @actor = Federails::Actor.find_param(params[:id])
    authorize @actor, policy_class: Federails::Client::ActorPolicy
    render_show
  end

  def lookup
    @actor = Federails::Actor.find_by_account(params.require(:account).strip)
    authorize @actor, policy_class: Federails::Client::ActorPolicy
    render_show
  end

  private

  def render_show
    respond_to do |format|
      if @actor.tombstoned?
        format.html { render Views::Actors::Gone.new, status: :gone }
        format.turbo_stream { render Views::Actors::Gone.new, status: :gone }
        format.json { render json: { error: "Gone" }, status: :gone }
      else
        format.html { render Views::Actors::Show.new(actor: @actor) }
        format.turbo_stream { render Views::Actors::Show.new(actor: @actor) }
        format.json { render json: actor_json }
      end
    end
  end

  def actor_json
    {
      id: @actor.id,
      username: @actor.username,
      name: @actor.name,
      federated_url: @actor.federated_url,
      at_address: @actor.at_address,
      profile_url: @actor.profile_url,
      local: @actor.local?
    }
  end
end
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `bin/rails test test/controllers/actors_controller_test.rb`
Expected: PASS

- [ ] **Step 7: 커밋**

```bash
git add app/controllers/actors_controller.rb app/views/actors/show.rb app/views/actors/gone.rb test/controllers/actors_controller_test.rb
git commit -m "feat: ActorsController + Phlex 뷰 추가 (show, lookup, gone)"
```

---

### Task 5: FollowingsController 생성

**Files:**
- Create: `app/controllers/followings_controller.rb`
- Create: `test/fixtures/federails_followings.yml`
- Create: `test/controllers/followings_controller_test.rb`

- [ ] **Step 1: Following 픽스처 생성**

```yaml
# test/fixtures/federails_followings.yml
# frozen_string_literal: true

john_follows_jane:
  actor_id: <%= ActiveRecord::FixtureSet.identify(:john_actor) %>
  target_actor_id: <%= ActiveRecord::FixtureSet.identify(:jane_actor) %>
  status: accepted
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>
```

- [ ] **Step 2: 테스트 작성**

```ruby
# test/controllers/followings_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class FollowingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @john = users(:john)
    @jane = users(:jane)
    @jane_actor = federails_actors(:jane_actor)
    @korean_user = users(:korean_user)
    @korean_actor = federails_actors(:korean_user_actor)
  end

  # --- Authentication ---

  test "POST create requires authentication" do
    post followings_path, params: { following: { target_actor_id: @jane_actor.id } }
    assert_redirected_to new_session_path
  end

  # --- new (remote follow) ---

  test "GET new redirects to actor show" do
    sign_in_as(@john)
    get new_following_path(uri: @jane_actor.federated_url)
    assert_redirected_to actor_path(assigns(:actor) || @jane_actor)
  end

  # --- create ---

  test "POST create with target_actor_id creates following" do
    sign_in_as(@john)
    assert_difference "Federails::Following.count", 1 do
      post followings_path, params: { following: { target_actor_id: @korean_actor.id } }
    end
  end

  # --- follow ---

  test "POST follow creates following and responds with turbo_stream" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: @korean_actor.at_address },
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  test "POST follow responds with json" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: @korean_actor.at_address },
      as: :json

    assert_response :created
  end

  test "POST follow with invalid account returns error" do
    sign_in_as(@john)
    post follow_followings_path,
      params: { account: "nonexistent@example.com" },
      as: :json

    assert_response :unprocessable_entity
  end

  # --- accept ---

  test "PUT accept accepts pending following" do
    following = Federails::Following.create!(
      actor: @korean_actor,
      target_actor: @john.federails_actor,
      status: :pending
    )

    sign_in_as(@john)
    put accept_following_path(following), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  # --- destroy ---

  test "DELETE destroy removes following and responds with turbo_stream" do
    following = Federails::Following.create!(
      actor: @john.federails_actor,
      target_actor: @korean_actor
    )

    sign_in_as(@john)
    delete following_path(following), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "follow_actions_#{@korean_actor.id}"
  end

  test "DELETE destroy responds with json" do
    following = Federails::Following.create!(
      actor: @john.federails_actor,
      target_actor: @korean_actor
    )

    sign_in_as(@john)
    delete following_path(following), as: :json

    assert_response :no_content
  end
end
```

- [ ] **Step 3: 테스트 실패 확인**

Run: `bin/rails test test/controllers/followings_controller_test.rb`
Expected: FAIL — FollowingsController 없음

- [ ] **Step 4: FollowingsController 구현**

```ruby
# app/controllers/followings_controller.rb
# frozen_string_literal: true

class FollowingsController < ApplicationController
  include Pundit::Authorization

  before_action :set_following, only: [:accept, :destroy]
  after_action :verify_authorized, except: [:new]

  def new
    actor = Federails::Actor.find_or_create_by_federation_url(params.require(:uri))
    redirect_to actor_path(actor)
  end

  def create
    @following = Federails::Following.new(following_params)
    @following.actor = Current.user.federails_actor
    authorize @following, policy_class: Federails::Client::FollowingPolicy

    save_and_render(@following.target_actor)
  end

  def follow
    authorize Federails::Following, policy_class: Federails::Client::FollowingPolicy

    begin
      @following = Federails::Following.new_from_account(
        params.require(:account),
        actor: Current.user.federails_actor
      )
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to root_path, alert: "해당 계정을 찾을 수 없습니다." }
        format.turbo_stream { head :unprocessable_entity }
        format.json { render json: { target_actor: ["does not exist"] }, status: :unprocessable_entity }
      end
      return
    end

    save_and_render(@following.target_actor)
  end

  def accept
    respond_to do |format|
      if @following.accept!
        format.html { redirect_to actor_path(@following.actor), notice: "팔로우 요청을 수락했습니다." }
        format.turbo_stream { render_follow_actions_stream(@following.actor) }
        format.json { render json: { status: @following.status }, status: :ok }
      else
        format.html { redirect_to actor_path(@following.actor), alert: "팔로우 요청 수락에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(@following.actor) }
        format.json { render json: @following.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    target_actor = @following.target_actor
    @following.destroy

    respond_to do |format|
      format.html { redirect_to actor_path(@following.actor), notice: "팔로우를 취소했습니다." }
      format.turbo_stream { render_follow_actions_stream(target_actor) }
      format.json { head :no_content }
    end
  end

  private

  def set_following
    @following = Federails::Following.find_param(params[:id])
    authorize @following, policy_class: Federails::Client::FollowingPolicy
  end

  def following_params
    params.require(:following).permit(:target_actor_id)
  end

  def save_and_render(target_actor)
    respond_to do |format|
      if @following.save
        format.html { redirect_to actor_path(Current.user.federails_actor), notice: "팔로우했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: { status: @following.status }, status: :created }
      else
        format.html { redirect_to actor_path(Current.user.federails_actor), alert: "팔로우에 실패했습니다." }
        format.turbo_stream { render_follow_actions_stream(target_actor) }
        format.json { render json: @following.errors, status: :unprocessable_entity }
      end
    end
  end

  def render_follow_actions_stream(actor)
    render turbo_stream: turbo_stream.replace(
      "follow_actions_#{actor.id}",
      Views::Followings::FollowActions.new(actor: actor)
    )
  end
end
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `bin/rails test test/controllers/followings_controller_test.rb`
Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add app/controllers/followings_controller.rb test/controllers/followings_controller_test.rb test/fixtures/federails_followings.yml
git commit -m "feat: FollowingsController 추가 (turbo_stream 지원)"
```

---

### Task 6: ERB 참조 변경 및 불필요 파일 삭제

**Files:**
- Modify: `app/views/layouts/federails/application.html.erb`
- Modify: `app/views/federails/client/common/_client_links.html.erb`
- Modify: `app/views/federails/client/actors/_lookup_form.html.erb`
- Delete: 불필요한 ERB 파일들

- [ ] **Step 1: layout 파일 헬퍼 변경**

`app/views/layouts/federails/application.html.erb`에서:
- `federails.client_actor_path(...)` → `actor_path(...)`
- `/app/feed` 또는 `federails.client_feed_url` → `feed_activities_path`
- `/app/actors/lookup` → `lookup_actors_path`

- [ ] **Step 2: `_client_links.html.erb` 헬퍼 변경**

`app/views/federails/client/common/_client_links.html.erb`에서:
- `federails.client_actors_url` 링크 줄 제거 (actors index 없음)
- `federails.client_activities_url` → `activities_url`
- `federails.client_feed_url` → `feed_activities_url`
- `federails.client_actor_path(...)` → `actor_path(...)`

- [ ] **Step 3: `_lookup_form.html.erb` 헬퍼 변경**

`app/views/federails/client/actors/_lookup_form.html.erb`에서:
- `federails.lookup_client_actors_url` → `lookup_actors_url`

- [ ] **Step 4: 불필요한 ERB 파일 삭제**

```bash
rm app/views/federails/client/actors/show.html.erb
rm app/views/federails/client/actors/gone.html.erb
rm app/views/federails/client/actors/index.html.erb
rm app/views/federails/client/followings/_follow_actions.html.erb
rm app/views/federails/client/followings/_follow.html.erb
rm app/views/federails/client/followings/_follower.html.erb
rm app/views/federails/client/followings/_form.html.erb
rm app/views/federails/client/followings/index.html.erb
rm app/views/federails/client/followings/show.html.erb
rm -f app/views/federails/client/followings/*.json.jbuilder
```

- [ ] **Step 5: 서버 시작하여 에러 없는지 확인**

Run: `bin/rails runner "puts 'OK'"`
Expected: `OK` 출력, 에러 없음

- [ ] **Step 6: 커밋**

```bash
git add -A
git commit -m "refactor: federails 헬퍼 참조를 앱 라우트 헬퍼로 변경 및 불필요 ERB 삭제"
```

---

### Task 7: 전체 테스트 및 수동 검증

- [ ] **Step 1: 전체 테스트 실행**

Run: `bin/rails test`
Expected: 모든 테스트 PASS

- [ ] **Step 2: 수동 검증 — actor show 페이지**

서버 시작 후 actor show 페이지 접속. FollowActions 컴포넌트가 정상 렌더링되는지, 팔로우 버튼이 동작하는지 확인.

- [ ] **Step 3: 수동 검증 — turbo_stream 동작**

팔로우 버튼 클릭 시 페이지 전체 리로드 없이 follow_actions 영역만 교체되는지 확인.

- [ ] **Step 4: 수동 검증 — activities stub**

`/activities`, `/activities/feed` 페이지 정상 접속 확인.

- [ ] **Step 5: 최종 커밋 (필요 시 수정)**

테스트/검증에서 발견된 이슈 수정 후 커밋.
