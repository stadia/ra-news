# 공개 Blog Index (`/@계정/blog`) + 관리 화면 분리 — 설계

> 작성일: 2026-07-06

## 배경 / 문제

blog 글을 계정별로 모아 보여주는 공개 페이지가 필요하다. URL 구조는
`/@계정/blog`가 해당 계정의 blog index 페이지가 된다.

현재 상태:

- `Post#post_type` enum: `short` / `blog` / `comment`. blog 글은 이미 별도 타입이다.
- 개별 blog 글은 `/posts/:id`(`posts#show`)로 공개 표시된다.
- `/@:username/blog` 라우트가 **이미 존재**하지만, `ProfilesController#blog`가
  `current_user == @user`로 막힌 **본인 전용 관리 페이지**(초안/발행/휴지통 목록 +
  수정/삭제/복원)로 쓰이고 있다.
- `/@:username/posts`는 해당 계정의 short 글 목록(공개)이다.

즉 원하는 URL이 이미 관리 페이지로 점유되어 있어, 공개 index로 전환하면서 관리
화면을 다른 곳으로 옮겨야 한다.

## 목표

- **`/@계정/blog`** = 해당 계정의 **공개** blog index. 발행된 blog 글만, 읽기 전용,
  카드 리스트. posts/comments 탭과 UX 일관.
- **`/@계정/blog/:slug`** = blog 글 **상세 보기**. blog을 계정 아래로 완전히
  네임스페이스화한다. 기존 `/posts/:slug`는 blog 글에 대해 **더 이상 열리지 않는다**
  (파괴적 변경, C안). short 글만 `/posts/:slug` 유지.
- 기존 **본인 전용 관리**(초안/발행/휴지통 + 수정/삭제/복원)는 **`/account/blog`**로
  이동. 진입점은 계정 설정 페이지(`/account/edit` → `Views::Users::Edit`)에 링크.
- 기존 프로필 탭 인프라(`ActivityTabs`, `render_activity_page`)를 그대로 재사용해
  변경을 최소화한다. blog 전용 매거진 레이아웃은 **추후 리뉴얼** 대상(범위 밖).

> **파괴적 변경 근거**: 현재 발행된 blog 글이 1개뿐이라 기존 `/posts/:slug` 링크
> 보존(리다이렉트)이 불필요. 깔끔한 새 구조를 택한다.

## 비목표 (YAGNI)

- blog 전용 독립 레이아웃/디자인 리뉴얼.
- 계정 설정 nav 전면 재편.
- blog 글 자체(`posts#show`)의 표현 변경.

## 설계

### 1. 라우트 (`config/routes.rb`)

- `get "/@:username/blog" → profiles#blog` **유지** (동작만 공개로 변경).
- blog 상세 신규 추가 (index 라우트 바로 뒤, 더 구체적 경로):

  ```ruby
  get "/@:username/blog/:slug", to: "posts#show", as: :user_profile_blog_post,
      format: false, constraints: { username: /[^\/]+/ }
  ```

- 관리 index 신규 추가 (인증 필요):

  ```ruby
  get "account/blog", to: "blog_posts#index", as: :account_blog
  ```

  `authenticate_user!`는 전역 before_action로 이미 적용된다.

### 2. `ProfilesController#blog` — 공개화

- `current_user == @user` 소유자 체크 **제거**.
- 발행 + 미삭제(kept) blog 글만 로드. `#posts` 액션과 동일하게 pagy 적용:

  ```ruby
  @pagy, @posts = pagy(@user.posts.published_blog.kept.order(published_at: :desc))
  ```

  (pagy 헬퍼/변수 명은 기존 `#posts` 구현을 따른다.)
- `@blog_drafts` / `@blog_published` / `@blog_trash` 로드 제거.
- `render_activity_page(:blog)` 호출은 유지하되, blog 분기가 공개 BlogList를
  렌더하도록 인자를 변경(아래 4, 6번).

### 3. `Components::Profiles::ActivityTabs` (`activity_tabs.rb:20`)

- blog 탭 링크를 `if own_profile?` 그룹에서 빼내어 **항상 노출**
  (posts / comments 와 동일 라인). followers/following/likes/boosts는 그대로 소유자
  전용 유지.

### 4. 뷰 분리 — 공개 vs 관리

**공개 — `Views::Profiles::BlogList` 재작성**

- 발행 글을 읽기 카드로 표시. `Views::Profiles::PostList`를 미러링:
  `Components::Posts::PostCard` + `Components::Pagination`.
- 인자: `user:`, `posts:`, `pagy:`, `liked_post_ids:`, `boosted_post_ids:`,
  `embedded: false`. (`PostList` 인터페이스와 정렬.)
- `embedded`일 때 `activity-list` turbo-frame 내부 렌더 유지.
- 수정/삭제/복원/휴지통 UI는 전부 제거(관리 뷰로 이동).

**관리 — `Views::BlogPosts::Index` 신설**

- 현재 `Views::Profiles::BlogList`의 관리 마크업(drafts/published/trash 섹션,
  `draft_row`/`published_row`/`trash_row`, 수정/삭제/복원/영구삭제 버튼)을 이관.
- ActivityTabs 없이 standalone 페이지. 자체 `content_for :title`과 헤더.
- 기존 `edit_blog_post_path` / `blog_post_path` / `undiscard_blog_post_path` /
  `destroy_permanently_blog_post_path` 링크는 그대로 사용.

### 5. `BlogPostsController#index` 신설

- current_user 기준으로 로드(기존 `profiles#blog` 로직 이관):

  ```ruby
  def index
    @drafts    = current_user.posts.blog.draft.kept.order(updated_at: :desc)
    @published = current_user.posts.blog.published.kept.order(published_at: :desc)
    @trash     = current_user.posts.blog.discarded.order(updated_at: :desc)
    render Views::BlogPosts::Index.new(
      user: current_user, drafts: @drafts, published: @published, trash: @trash
    )
  end
  ```

- 리다이렉트 대상 변경:
  - `undiscard`(복원, 96행) / `destroy_permanently`(영구삭제, 106행):
    `user_profile_blog_path` → `account_blog_path`
  - `publish`(40행) / `update`(65행) / `publish`(79행):
    `post_path(@post)` → `user_profile_blog_post_path` (6c 참조)

### 6. `Views::Profiles::Show` (`show.rb:134` `when :blog`)

- blog 탭 인라인 렌더를 공개 BlogList 인터페이스에 맞춤: drafts/published/trash 대신
  `posts:` + `pagy:` + liked/boosted ids 전달. `#blog`가 세팅하는 인스턴스 변수와
  일치시킨다.

### 6b. `PostsController#show` — blog 상세 분기

slug은 `friendly_id :random_slug`로 **전역 고유**하므로 username은 vanity/검증용이다.
`show`의 조회를 라우트에 따라 분기한다:

```ruby
def show
  post =
    if params[:username] # /@:username/blog/:slug
      User.find_by!(username: params[:username])
          .posts.published_blog.kept
          .includes(POST_SHOW_INCLUDES)
          .find_by!(slug: params[:slug])
    else                 # /posts/:slug — blog 글은 여기서 열리지 않음
      Post.where.not(post_type: :blog)
          .includes(POST_SHOW_INCLUDES)
          .find_by!(slug: params[:id])
    end
  # 이하 스레드 구성/렌더는 기존 그대로
end
```

- 잘못된 username·미발행·discarded blog → `RecordNotFound`(404).
- `/posts/:slug`에서 blog 글 → `where.not(post_type: :blog)`로 404 (C안 파괴적).
- 기존 `.includes(...)` eager load는 상수 등으로 공유.

### 6c. blog 글 링크 헬퍼

blog 글은 새 URL, 그 외는 기존 `post_path`. 앱 레벨 URL 헬퍼 신설
(예: `ApplicationHelper#post_permalink_path(post)`):

```ruby
def post_permalink_path(post)
  if post.blog?
    user_profile_blog_post_path(username: post.user.username, slug: post)
  else
    post_path(post)
  end
end
```

교체 대상:

- `Components::Posts::PostCard` — `post_path(@post)` 3곳(67 타임스탬프, 118 blog
  제목, 123 더보기) → `post_permalink_path(@post)`.
- `BlogPostsController` 리다이렉트 3곳(40 publish, 65 update, 79 publish) →
  `user_profile_blog_post_path(username: @post.user.username, slug: @post)`
  (항상 blog이므로 직접 호출).
- `Views::BlogPosts::Index`의 발행 글 미리보기 링크 → `post_permalink_path`.
- `ReplyNotificationJob`(52행) — parent_post가 blog일 수 있음. 동일 분기의
  `*_url` 버전 사용(알림은 절대 URL 필요).

### 7. 관리 진입점 — 계정 설정 페이지

- `Views::Users::Edit`(`app/views/users/edit.rb`)에 "블로그 글 관리 →"
  링크(`account_blog_path`) 추가.

### 8. i18n (en / ja / ko)

- 기존 `profiles.activity_tabs.blog`, `profiles.blog_list.*` 재사용.
- 신규: `account.blog.title`(관리 페이지 제목), 설정 페이지의 관리 링크 라벨.
  3개 로케일 모두 추가.

## 테스트

- **request spec `profiles#blog` (공개)**: 로그인 없이 접근 가능, 발행 글만 노출,
  초안/휴지통 글은 노출 안 됨.
- **request spec `blog_posts#index` (관리)**: 인증 필요, current_user의
  drafts/published/trash만 노출. 항상 current_user 스코프라 타인 것 노출 불가.
- **request spec 리다이렉트**: undiscard/destroy_permanently 후 `account_blog_path`로.
  publish/update 후 `user_profile_blog_post_path`로.
- **request spec blog 상세**: `/@user/blog/:slug`가 발행 blog 글 렌더. 미발행/타인
  slug → 404. `/posts/:slug`에 blog slug → 404. short 글은 `/posts/:slug` 정상.
- **헬퍼 spec**: `post_permalink_path` — blog은 `/@user/blog/:slug`, short은
  `/posts/:slug`.
- **뷰 spec**: 공개 `Views::Profiles::BlogList`가 PostCard로 발행 글을 렌더, 관리
  UI(수정/삭제) 미포함.

## 영향 파일 요약

| 파일 | 변경 |
|------|------|
| `config/routes.rb` | `/@:username/blog/:slug`, `account/blog` 라우트 추가 |
| `app/controllers/posts_controller.rb` | `#show` blog/short 조회 분기 |
| `app/controllers/profiles_controller.rb` | `#blog` 공개화, `render_activity_page(:blog)` 분기 인자 |
| `app/controllers/blog_posts_controller.rb` | `#index` 추가, 리다이렉트 5곳(publish/update/undiscard/destroy_permanently) 변경 |
| `app/helpers/application_helper.rb` | `post_permalink_path` 신설 |
| `app/components/profiles/activity_tabs.rb` | blog 탭 항상 노출 |
| `app/components/posts/post_card.rb` | `post_path` → `post_permalink_path` 3곳 |
| `app/jobs/reply_notification_job.rb` | blog parent 링크 분기 |
| `app/views/profiles/blog_list.rb` | 공개 읽기 리스트로 재작성 |
| `app/views/blog_posts/index.rb` | 신설 (관리 화면) |
| `app/views/profiles/show.rb` | blog 탭 렌더 인자 변경 |
| `app/views/users/edit.rb` | 관리 링크 추가 |
| `config/locales/*.yml` | `account.blog.*` 등 추가 |
| spec 파일들 | 위 테스트 |
