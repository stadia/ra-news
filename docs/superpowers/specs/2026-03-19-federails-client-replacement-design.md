# Federails Client 교체 설계

Federails 엔진의 client 컨트롤러/뷰를 비활성화하고, 앱 자체 컨트롤러 + Phlex 뷰 + Turbo Stream으로 대체한다.

## 배경

- Federails 엔진의 client 컨트롤러는 HTML/JSON 응답만 지원, Turbo Stream 미지원
- 뷰가 ERB이고 앱은 Phlex로 전환 중
- 엔진 컨트롤러를 override(prepend)하는 방식은 유지보수가 어렵다

## 결정 사항

| 항목 | 결정 |
|---|---|
| 접근 방식 | 엔진 client 비활성화 + 앱에서 새로 구현 |
| 라우트 경로 | `/followings`, `/actors`, `/activities` (기존 `/app/...` 제거) |
| 뷰 | Phlex |
| Turbo Stream | 모든 mutation 액션에 추가 |
| Pundit 인가 | 엔진의 기존 Policy 클래스 재활용 |
| Activities | stub 컨트롤러 + 기존 ERB 뷰 위임 (별도 작업으로 Phlex 전환) |
| Actors | show, lookup만 구현 (index 제외) |
| FollowActions 컴포넌트 | DOM ID 기반으로 어느 페이지에서든 turbo_stream 교체 가능 |

## 1. 설정 변경

### config/federails.yml

```yaml
defaults: &defaults
  # ...
  client_routes_path: null   # 기존: app
```

### config/initializers/federails.rb

```ruby
Federails.configure do |config|
  config.logger = Rails.logger
  config.remote_follow_url_method = :new_following_url
end
```

## 2. 라우트

```ruby
# config/routes.rb

# Followings
resources :followings, only: [:new, :create, :destroy] do
  collection do
    post :follow
  end
  member do
    put :accept
  end
end

# Actors (show + lookup만)
resources :actors, only: [:show] do
  collection do
    get :lookup
  end
end

# Activities (stub — 기존 ERB 위임)
resources :activities, only: [:index] do
  collection do
    get :feed
  end
end
resources :actors, only: [] do
  resources :activities, only: [:index]
end
```

### 라우트 헬퍼 매핑

| 기존 (엔진) | 신규 (앱) |
|---|---|
| `federails.client_following_path(f)` | `following_path(f)` |
| `federails.follow_client_followings_path` | `follow_followings_path` |
| `federails.accept_client_following_path(f)` | `accept_following_path(f)` |
| `federails.new_client_following_url` | `new_following_url` |
| `federails.client_actor_path(a)` | `actor_path(a)` |
| `federails.client_actor_url(a)` | `actor_url(a)` |
| `federails.client_actors_url` | 제거 (actors index 없음) |
| `federails.lookup_client_actors_url` | `lookup_actors_url` |
| `federails.client_actor_activities_path(a)` | `actor_activities_path(a)` |
| `federails.client_activities_url` | `activities_url` |
| `federails.client_feed_url` | `feed_activities_url` |

## 3. 컨트롤러

### FollowingsController

`ApplicationController` 상속. `include Pundit::Authorization`. 인증 필수 (모든 액션).

| 액션 | HTTP | 설명 | 응답 형식 |
|---|---|---|---|
| `new` | GET | remote follow landing. uri 파라미터로 actor 찾아서 `actor_path`로 리다이렉트 | html (redirect) |
| `create` | POST | `target_actor_id`로 Following 생성 | html, turbo_stream, json |
| `follow` | POST | `account`(at_address)로 Following 생성. 에러 시 `root_path`로 redirect | html, turbo_stream, json |
| `accept` | PUT | pending following 수락 | html, turbo_stream, json |
| `destroy` | DELETE | following 삭제 | html, turbo_stream, json |

turbo_stream 응답: `turbo_stream.replace("follow_actions_#{actor.id}")`로 FollowActions Phlex 컴포넌트 교체.

html 응답: 엔진과 동일하게 적절한 페이지로 redirect. `follow` 에러 시 `root_path` (actors index 없으므로).

json 응답: `render json:` 인라인으로 처리. 기존 jbuilder 뷰 불사용.

### ActorsController (stub)

`ApplicationController` 상속. `include Pundit::Authorization`. `allow_unauthenticated_access`.

| 액션 | HTTP | 설명 | 응답 형식 |
|---|---|---|---|
| `show` | GET | actor 상세. tombstoned → `Views::Actors::Gone` 렌더 | html, turbo_stream, json |
| `lookup` | GET | account로 actor 검색 후 show와 동일 렌더링 | html, turbo_stream, json |

json 응답: `render json:` 인라인 (actor 속성 직접 직렬화). tombstoned 시 `{ error: ... }` 반환.

### ActivitiesController (stub)

`ApplicationController` 상속. `include Pundit::Authorization`.

| 액션 | HTTP | 설명 | 응답 형식 |
|---|---|---|---|
| `index` | GET | 활동 목록. `actor_id` 파라미터로 필터 가능 | html (기존 ERB 위임) |
| `feed` | GET | 로그인 유저의 피드 | html (기존 ERB 위임) |

Activities는 `render template: "federails/client/activities/..."` 로 기존 ERB 뷰를 그대로 사용한다. Phlex 전환은 별도 작업.

**주의**: 기존 ERB 뷰(`_activity.html.erb` 등)가 `federails.*` 라우트 헬퍼를 참조하므로, Activities stub이 동작하려면 해당 ERB 파일의 헬퍼도 앱 라우트 헬퍼로 변경해야 한다. 이 작업은 Section 6의 참조 변경에 포함.

## 4. Phlex 뷰

### Views::Followings::FollowActions

```
app/views/followings/follow_actions.rb
```

핵심 컴포넌트. `initialize(actor:)`.

- 외부 div에 `id="follow_actions_#{actor.id}"` — turbo_stream 타겟
- `Current.user`와 `Federails::Client::FollowingPolicy`로 인가 체크
- 상태별 렌더링:
  - 내 계정: 안내 텍스트
  - 이미 팔로우 중: 상태 표시 + 언팔로우 버튼
  - 팔로우 안 함: 팔로우 버튼
  - 상대가 나를 팔로우 요청 (pending): 수락 버튼
  - 상대가 나를 팔로우 중: 안내 텍스트
  - 비로그인: fediverse 검색 안내
- `button_to` URL은 앱 라우트 헬퍼 사용

### Views::Actors::Show

```
app/views/actors/show.rb
```

기존 `federails/client/actors/show.html.erb`를 Phlex로 전환.
내부에서 `Views::Followings::FollowActions` 컴포넌트를 렌더.

### Views::Actors::Gone

```
app/views/actors/gone.rb
```

tombstoned actor용 에러 페이지. HTTP 410 Gone 상태로 렌더.

## 5. Turbo Stream 흐름

```
사용자: Follow 버튼 클릭
  → POST /followings/follow (Accept: text/vnd.turbo-stream.html)
  → FollowingsController#follow
  → Following 생성 성공
  → turbo_stream.replace("follow_actions_#{actor.id}") {
      render Views::Followings::FollowActions.new(actor: actor)
    }
  → 브라우저: #follow_actions_#{actor.id} 영역 교체
    (팔로우 버튼 → "팔로우 중 + 언팔로우 버튼"으로 변경)
```

어느 페이지에서든 `Views::Followings::FollowActions`를 렌더하면 해당 DOM ID가 생기고, turbo_stream 응답이 자동으로 해당 영역을 교체한다.

## 6. 기존 참조 변경

앱 내 `federails.*` 헬퍼 사용처를 앱 라우트 헬퍼로 변경해야 한다.

변경 대상 파일:
- `app/views/federails/client/actors/show.html.erb` → Phlex 전환으로 제거
- `app/views/federails/client/followings/_follow_actions.html.erb` → Phlex 전환으로 제거
- `app/views/federails/client/followings/_follow.html.erb` → Phlex 전환으로 제거
- `app/views/federails/client/followings/_follower.html.erb` → Phlex 전환으로 제거
- `app/views/federails/client/common/_client_links.html.erb` — 헬퍼 변경 + actors index 링크 제거 (actors index 없음)
- `app/views/federails/client/activities/_activity.html.erb` — 헬퍼 변경
- `app/views/federails/client/actors/index.html.erb` — 헬퍼 변경
- `app/views/federails/client/actors/_lookup_form.html.erb` — 헬퍼 변경
- `app/views/layouts/federails/application.html.erb` — 헬퍼 변경 + 하드코딩 경로(`/app/feed`, `/app/actors/lookup`)를 라우트 헬퍼로 변환

## 7. 테스트

- FollowingsController: 각 액션의 html, turbo_stream, json 응답 테스트
- ActorsController: show, lookup의 정상/tombstoned 응답 테스트
- ActivitiesController: index, feed의 기본 동작 테스트
- FollowActions 컴포넌트: 상태별 렌더링 테스트 (팔로우/언팔로우/수락/비로그인)
- 통합: turbo_stream 응답이 올바른 DOM ID를 타겟하는지 확인

## 범위 외

- Activities 뷰의 Phlex 전환 (별도 작업)
- Actors index 페이지 (제외)
- `_form.html.erb` (어디서도 사용되지 않음)
