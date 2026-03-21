# Social Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Feed를 X.com/Mastodon 스타일의 소셜 피드로 개편 — Post 작성 form, 무한 스크롤, 인라인 답글, 상대 시간 표시

**Architecture:** ActivitiesController#feed에 pagy_countless 페이지네이션 추가, PostsController#create로 post/reply 생성, Turbo Frames로 무한 스크롤, Turbo Stream으로 실시간 삽입

**Tech Stack:** Rails 8.1, Phlex, Turbo Frames/Streams, Stimulus, pagy_countless, Tailwind CSS v4

---

## File Structure

| 파일 | 역할 |
|------|------|
| `app/controllers/posts_controller.rb` | 신규 — Post create 액션 |
| `app/controllers/activities_controller.rb` | 수정 — feed에 pagy_countless 추가 |
| `config/routes.rb` | 수정 — posts에 :create 추가 |
| `app/views/activities/feed.rb` | 수정 — post form, 무한 스크롤, 상대 시간, 답글 버튼 |
| `app/components/posts/post_card.rb` | 신규 — 단일 post 카드 컴포넌트 (재사용) |
| `app/components/posts/post_form.rb` | 신규 — Post 작성 form 컴포넌트 |
| `app/components/posts/reply_form.rb` | 신규 — 인라인 답글 form 컴포넌트 |
| `app/javascript/controllers/infinite_scroll_controller.js` | 신규 — Intersection Observer |
| `app/views/posts/create.turbo_stream.rb` | 신규 — Turbo Stream 응답 (Phlex) |
| `test/controllers/posts_controller_test.rb` | 신규 — PostsController 테스트 |

---

### Task 1: Routes & PostsController 뼈대

**Files:**
- Modify: `config/routes.rb:7`
- Create: `app/controllers/posts_controller.rb`
- Create: `test/controllers/posts_controller_test.rb`

- [ ] **Step 1: Route 추가**

`config/routes.rb` 에서 `resources :posts, only: [ :show ]` → `resources :posts, only: [ :show, :create ]` 변경

```ruby
resources :posts, only: [ :show, :create ]
```

- [ ] **Step 2: PostsController 작성**

```ruby
# app/controllers/posts_controller.rb
# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :require_authentication, only: [ :create ]

  def create
    @post = Current.user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream
        format.html { redirect_to feed_path }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
      end
    end
  end

  private

  def post_params
    params.expect(post: [ :body, :parent_id ])
  end
end
```

- [ ] **Step 3: 기본 테스트 작성**

```ruby
# test/controllers/posts_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:default)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "테스트 포스트입니다." } }, as: :turbo_stream
    end
    assert_response :success
  end

  test "should create reply post" do
    parent = Post.create!(body: "부모 포스트", user: @user)
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: "답글입니다.", parent_id: parent.id } }, as: :turbo_stream
    end
    assert_response :success
  end

  test "should reject empty body" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { body: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "should require authentication" do
    delete logout_url
    post posts_url, params: { post: { body: "test" } }
    assert_redirected_to new_session_url
  end
end
```

- [ ] **Step 4: 테스트 실행 확인**

Run: `bin/rails test test/controllers/posts_controller_test.rb`
Expected: 4 tests pass (turbo_stream 응답 뷰가 아직 없으므로 일부 fail 가능 — Task 4에서 해결)

- [ ] **Step 5: 커밋**

```bash
git add config/routes.rb app/controllers/posts_controller.rb test/controllers/posts_controller_test.rb
git commit -m "feat: PostsController#create 추가 — post 및 reply 생성 엔드포인트"
```

---

### Task 2: PostCard 컴포넌트

**Files:**
- Create: `app/components/posts/post_card.rb`

- [ ] **Step 1: PostCard 컴포넌트 작성**

Comment 컴포넌트 패턴을 참고하여 작성. 상대 시간, 답글 버튼, 스레드 들여쓰기 포함.

```ruby
# app/components/posts/post_card.rb
# frozen_string_literal: true

class Components::Posts::PostCard < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include PhlexIcons

  def initialize(post:, depth: 0)
    @post = post
    @depth = depth
  end

  def view_template
    div(
      id: dom_id(@post),
      class: wrapper_classes,
      data: { controller: "reply-form" }
    ) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm hover:border-border-strong transition-all duration-200") do
        render RubyUI::CardContent.new(class: "p-4 sm:p-5 space-y-3") do
          post_header
          post_body
          post_actions if @depth.zero?
        end
      end
      reply_form_section if @depth.zero?
    end
  end

  private

  def wrapper_classes
    classes = []
    if @depth.positive?
      classes << "ml-4 sm:ml-8 border-l-2 border-border-muted pl-3 sm:pl-4"
    end
    classes.join(" ")
  end

  def post_header
    div(class: "flex items-center gap-3") do
      # Avatar
      render RubyUI::Avatar.new(class: "h-8 w-8 sm:h-10 sm:w-10 shrink-0") do
        render RubyUI::AvatarFallback.new(class: "bg-linear-to-r from-info-solid to-brand-solid text-brand-foreground text-sm font-bold") do
          plain author_name.first.to_s.upcase
        end
      end

      div(class: "flex-1 min-w-0") do
        span(class: "font-semibold text-content text-sm") { author_name }
        time(
          class: "block text-xs text-content-muted",
          datetime: @post.created_at.iso8601,
          title: I18n.l(@post.created_at, format: :long)
        ) do
          plain "#{view_context.time_ago_in_words_korean(@post.created_at)} 전"
        end
      end
    end
  end

  def post_body
    p(class: "text-content leading-relaxed wrap-break-word whitespace-pre-wrap") do
      plain @post.body
    end
  end

  def post_actions
    div(class: "flex items-center gap-4 text-sm text-content-muted") do
      # Reply button
      render RubyUI::Button.new(
        variant: :ghost,
        size: :sm,
        data: { action: "reply-form#toggle" },
        class: "inline-flex items-center gap-1 text-content-muted hover:text-info-text transition-colors hover:bg-transparent p-0"
      ) do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-4 h-4")
        if @post.children_count.positive?
          span { @post.children_count.to_s }
        end
      end
    end
  end

  def reply_form_section
    div(data: { reply_form_target: "form" }, class: "hidden mt-2") do
      render Components::Posts::ReplyForm.new(parent_post: @post)
    end
  end

  def author_name
    @post.user&.name || @post.federails_actor&.name || "알 수 없음"
  end
end
```

- [ ] **Step 2: 커밋**

```bash
git add app/components/posts/post_card.rb
git commit -m "feat: PostCard Phlex 컴포넌트 — 아바타, 상대 시간, 답글 버튼"
```

---

### Task 3: PostForm & ReplyForm 컴포넌트

**Files:**
- Create: `app/components/posts/post_form.rb`
- Create: `app/components/posts/reply_form.rb`

- [ ] **Step 1: PostForm 컴포넌트 (상단 작성 폼)**

CommentForm 패턴을 참고. character_count_controller 재사용.

```ruby
# app/components/posts/post_form.rb
# frozen_string_literal: true

class Components::Posts::PostForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

  def initialize(post: Post.new)
    @post = post
  end

  def view_template
    div(
      id: "post_form",
      class: "mb-6",
      data: {
        controller: "character-count",
        character_count_max_length_value: "500"
      }
    ) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm") do
        render RubyUI::CardContent.new(class: "p-4 sm:p-5") do
          form_with(
            model: @post,
            url: view_context.posts_path,
            class: "space-y-3",
            data: { action: "turbo:submit-end->character-count#reset" }
          ) do |f|
            body_field(f)
            form_footer(f)
          end
        end
      end
    end
  end

  private

  def body_field(f)
    f.text_area :body,
      rows: 3,
      class: "w-full px-4 py-3 rounded-lg border border-border-muted bg-surface text-content placeholder:text-content-muted hover:border-border-strong focus:border-transparent focus:ring-2 focus:ring-state-info transition-all duration-200 resize-none text-sm",
      placeholder: "무슨 생각을 하고 계신가요?",
      data: { character_count_target: "input", action: "input->character-count#updateCount" }
  end

  def form_footer(f)
    div(class: "flex items-center justify-between") do
      div(class: "text-xs text-content-muted") do
        span(data: { character_count_target: "counter" }) { "0" }
        plain " 자"
      end
      f.submit "게시",
        class: "inline-flex items-center px-5 py-2 bg-info-solid hover:bg-info-solid-hover text-brand-foreground text-sm font-medium rounded-lg transition-colors duration-200 cursor-pointer"
    end
  end
end
```

- [ ] **Step 2: ReplyForm 컴포넌트 (인라인 답글)**

CommentReplyForm 패턴을 참고.

```ruby
# app/components/posts/reply_form.rb
# frozen_string_literal: true

class Components::Posts::ReplyForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

  def initialize(parent_post:)
    @parent_post = parent_post
  end

  def view_template
    div(
      class: "ml-4 sm:ml-8",
      data: {
        controller: "character-count",
        character_count_max_length_value: "500"
      }
    ) do
      form_with(
        model: Post.new,
        url: view_context.posts_path,
        class: "space-y-2",
        data: { action: "turbo:submit-end->reply-form#close" }
      ) do |f|
        f.hidden_field :parent_id, value: @parent_post.id

        f.text_area :body,
          rows: 2,
          class: "w-full px-3 py-2 rounded-lg border border-border-muted bg-surface text-content placeholder:text-content-muted hover:border-border-strong focus:border-transparent focus:ring-2 focus:ring-state-info transition-all duration-200 resize-none text-sm",
          placeholder: "답글을 입력하세요...",
          data: { character_count_target: "input", action: "input->character-count#updateCount" }

        div(class: "flex items-center justify-between") do
          div(class: "text-xs text-content-muted") do
            span(data: { character_count_target: "counter" }) { "0" }
            plain " 자"
          end
          div(class: "flex items-center gap-2") do
            render RubyUI::Button.new(
              variant: :ghost,
              size: :sm,
              data: { action: "reply-form#toggle" },
              class: "text-content-muted hover:text-content text-xs hover:bg-transparent"
            ) { "취소" }
            f.submit "답글",
              class: "inline-flex items-center px-4 py-1.5 bg-info-solid hover:bg-info-solid-hover text-brand-foreground text-xs font-medium rounded-md transition-colors duration-200 cursor-pointer"
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: 커밋**

```bash
git add app/components/posts/post_form.rb app/components/posts/reply_form.rb
git commit -m "feat: PostForm, ReplyForm Phlex 컴포넌트 — 글자수 카운터 포함"
```

---

### Task 4: Turbo Stream 응답

**Files:**
- Create: `app/views/posts/create.turbo_stream.rb`

- [ ] **Step 1: Turbo Stream 응답 작성**

Phlex 기반 turbo_stream 응답. 성공 시 post 삽입 + form 리셋, 실패 시 에러 표시.

```ruby
# app/views/posts/create.turbo_stream.rb
# frozen_string_literal: true

class Views::Posts::CreateTurboStream < Views::Base
  include Phlex::Rails::Helpers::TurboStream

  def initialize(post:)
    @post = post
  end

  def view_template
    if @post.persisted?
      if @post.parent_id.present?
        # 답글: 부모 post의 replies 영역에 append
        turbo_stream.append("replies_#{@post.parent_id}") do
          render Components::Posts::PostCard.new(post: @post, depth: 1)
        end
      else
        # 최상위 post: feed 상단에 prepend
        turbo_stream.prepend("posts_list") do
          render Components::Posts::PostCard.new(post: @post)
        end
      end

      # form 리셋 — 빈 form으로 교체
      turbo_stream.replace("post_form") do
        render Components::Posts::PostForm.new
      end
    else
      # 에러 시 form을 에러 포함하여 교체
      turbo_stream.replace("post_form") do
        render Components::Posts::PostForm.new(post: @post)
      end
    end
  end
end
```

- [ ] **Step 2: PostsController에서 이 뷰 렌더링하도록 확인**

`PostsController#create`에서 `format.turbo_stream`이 호출되면 Rails가 자동으로 `views/posts/create.turbo_stream.rb`를 찾음. Phlex에서는 명시적 render가 필요할 수 있음:

```ruby
format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post) }
```

PostsController의 respond_to 블록 양쪽(성공/실패) 모두 이 뷰를 렌더링하도록 수정:

```ruby
respond_to do |format|
  if @post.save
    format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post) }
    format.html { redirect_to feed_path }
  else
    format.turbo_stream { render Views::Posts::CreateTurboStream.new(post: @post), status: :unprocessable_entity }
    format.html { redirect_to feed_path, alert: "포스트 작성에 실패했습니다." }
  end
end
```

- [ ] **Step 3: PostForm에 에러 표시 추가**

`PostForm#view_template`에서 `@post.errors.any?`일 때 에러 메시지 표시:

```ruby
# body_field 전에 추가
if @post.errors.any?
  div(class: "text-sm text-danger-text") do
    @post.errors.full_messages.each { |msg| p { msg } }
  end
end
```

- [ ] **Step 4: 테스트 실행**

Run: `bin/rails test test/controllers/posts_controller_test.rb`
Expected: 4 tests pass

- [ ] **Step 5: 커밋**

```bash
git add app/views/posts/create.turbo_stream.rb app/controllers/posts_controller.rb app/components/posts/post_form.rb
git commit -m "feat: Post create Turbo Stream 응답 — prepend/append + form 리셋"
```

---

### Task 5: Feed View 개편 + 무한 스크롤

**Files:**
- Modify: `app/controllers/activities_controller.rb:18-29`
- Modify: `app/views/activities/feed.rb`
- Create: `app/javascript/controllers/infinite_scroll_controller.js`

- [ ] **Step 1: ActivitiesController에 pagy 추가**

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  include Pundit::Authorization
  include Pagy::Method

  after_action :verify_authorized
  before_action :require_authentication, only: [ :feed ]

  # ... index 유지 ...

  def feed
    authorize Federails::Activity, policy_class: Federails::Client::ActivityPolicy
    actor = Current.user.federails_actor
    following_actor_ids = Federails::Following.accepted.where(actor: actor).select(:target_actor_id)

    posts = Post
      .where(federails_actor_id: following_actor_ids)
      .or(Post.where(user_id: Current.user.id))
      .where(parent_id: nil)  # 최상위 post만 (답글은 children으로)
      .order(created_at: :desc)

    @pagy, @posts = pagy_countless(posts, limit: 20)

    render Views::Activities::Feed.new(posts: @posts, pagy: @pagy)
  end
end
```

주의: `.where(parent_id: nil)` 추가 — 최상위 post만 가져오고, 답글은 각 post의 children으로 로드.

- [ ] **Step 2: Feed View 개편**

```ruby
# app/views/activities/feed.rb
# frozen_string_literal: true

class Views::Activities::Feed < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(posts:, pagy:)
    @posts = posts
    @pagy = pagy
  end

  def view_template
    content_for :title, "피드 | Ruby-News"

    div(class: "max-w-2xl mx-auto") do
      # Post 작성 form
      render Components::Posts::PostForm.new

      # Posts list
      div(id: "posts_list", class: "space-y-4") do
        if @posts.empty? && @pagy.page == 1
          render_empty_state
        else
          @posts.each do |post|
            render Components::Posts::PostCard.new(post: post)
            # 답글 렌더링
            render_replies(post) if post.children_count.positive?
          end
        end
      end

      # 무한 스크롤 — 다음 페이지 Turbo Frame
      render_next_page_frame if @pagy.next
    end
  end

  private

  def render_replies(post)
    div(id: "replies_#{post.id}", class: "space-y-2") do
      post.children.includes(:user, :federails_actor).order(:created_at).each do |reply|
        render Components::Posts::PostCard.new(post: reply, depth: 1)
      end
    end
  end

  def render_empty_state
    render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm") do
      render RubyUI::CardContent.new(class: "p-8 text-content-secondary text-center") do
        plain "표시할 포스트가 없습니다. 다른 사용자를 팔로우하거나 첫 포스트를 작성해보세요!"
      end
    end
  end

  def render_next_page_frame
    turbo_frame_tag(
      "feed_page_#{@pagy.next}",
      src: view_context.feed_path(page: @pagy.next),
      loading: :lazy,
      data: { controller: "infinite-scroll" }
    ) do
      div(class: "py-8 text-center text-content-muted") do
        plain "불러오는 중..."
      end
    end
  end
end
```

- [ ] **Step 3: 무한 스크롤용 feed 페이지 프래그먼트**

다음 페이지 요청 시, Turbo Frame 안에 posts + 다음 frame만 렌더링.
ActivitiesController#feed는 Turbo Frame 요청이면 같은 뷰를 렌더링하지만, Turbo가 자동으로 해당 frame만 추출함.

이를 위해 Feed 뷰가 turbo_frame_tag로 감싸진 content를 반환해야 함. 수정:

```ruby
def view_template
  content_for :title, "피드 | Ruby-News"

  if @pagy.page == 1
    div(class: "max-w-2xl mx-auto") do
      render Components::Posts::PostForm.new
      posts_and_pagination
    end
  else
    # 2페이지 이상은 turbo_frame으로 감싸서 반환
    turbo_frame_tag("feed_page_#{@pagy.page}") do
      posts_and_pagination
    end
  end
end

private

def posts_and_pagination
  # 1페이지면 wrapper div 포함
  if @pagy.page == 1
    div(id: "posts_list", class: "space-y-4") do
      render_posts
    end
  else
    render_posts
  end
  render_next_page_frame if @pagy.next
end

def render_posts
  if @posts.empty? && @pagy.page == 1
    render_empty_state
  else
    @posts.each do |post|
      render Components::Posts::PostCard.new(post: post)
      render_replies(post) if post.children_count.positive?
    end
  end
end
```

- [ ] **Step 4: infinite_scroll_controller.js 작성**

```javascript
// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

// Turbo Frame의 lazy loading을 트리거하는 Intersection Observer
// turbo_frame_tag에 loading: :lazy와 함께 사용
export default class extends Controller {
  connect() {
    // Turbo의 lazy loading이 자동으로 처리하므로
    // 이 컨트롤러는 로딩 상태 관리에만 사용
    this.element.addEventListener("turbo:before-fetch-request", () => {
      this.element.setAttribute("aria-busy", "true")
    })

    this.element.addEventListener("turbo:frame-load", () => {
      this.element.removeAttribute("aria-busy")
    })
  }
}
```

참고: `turbo_frame_tag`에 `loading: :lazy`를 설정하면 Turbo가 Intersection Observer를 내부적으로 사용하여 자동으로 lazy-load함. 별도의 Intersection Observer 구현이 필요 없음.

- [ ] **Step 5: 테스트 실행**

Run: `bin/rails test test/controllers/posts_controller_test.rb`
Expected: All tests pass

- [ ] **Step 6: 수동 확인**

Run: `bin/dev`
- `/feed` 접속하여 post form 표시 확인
- Post 작성 → 상단에 추가 확인
- 답글 작성 → 부모 아래 추가 확인
- 스크롤 시 다음 페이지 로드 확인
- 상대 시간 표시 확인

- [ ] **Step 7: 커밋**

```bash
git add app/controllers/activities_controller.rb app/views/activities/feed.rb app/javascript/controllers/infinite_scroll_controller.js
git commit -m "feat: Social feed — 무한 스크롤, post form, 인라인 답글, 상대 시간"
```

---

### Task 6: N+1 방지 및 최종 정리

**Files:**
- Modify: `app/controllers/activities_controller.rb`
- Modify: `app/views/activities/feed.rb`

- [ ] **Step 1: Eager loading 추가**

ActivitiesController#feed에서:

```ruby
posts = Post
  .includes(:user, :federails_actor)
  .where(federails_actor_id: following_actor_ids)
  .or(Post.where(user_id: Current.user.id))
  .where(parent_id: nil)
  .order(created_at: :desc)
```

- [ ] **Step 2: children_count counter_cache 확인**

Post 모델에 `acts_as_nested_set`이 `children_count`를 관리함. DB에 `children_count` 컬럼이 있는지 확인:

Run: `bin/rails runner "puts Post.column_names.include?('children_count')"`
Expected: `true`

- [ ] **Step 3: 전체 테스트 실행**

Run: `bin/rails test`
Expected: All tests pass

- [ ] **Step 4: 커밋**

```bash
git add app/controllers/activities_controller.rb
git commit -m "perf: feed 쿼리에 eager loading 추가"
```
