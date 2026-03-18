# ERB → Phlex 뷰 변환 설계

**날짜:** 2026-03-18
**브랜치:** feature/rubyui

---

## 목표

`app/views/` 디렉토리에 남아 있는 HTML ERB 템플릿을 Phlex 뷰 컴포넌트로 전환한다.
madmin, federails, mailer, JSON 템플릿은 변환하지 않는다.

---

## 현재 상태 (이미 변환된 파일)

다음 파일들은 이미 Phlex로 변환 완료되어 컨트롤러에서 `render Views::*` 형태로 호출 중:
- `views/home/index.rb` → `Views::Home::Index`
- `views/articles/index.rb` → `Views::Articles::Index`
- `views/articles/others.rb` → `Views::Articles::Others`
- `views/articles/new.rb` → `Views::Articles::New`
- `views/users/` — 전체 변환됨
- `views/sessions/new.rb` → `Views::Sessions::New`
- `views/profiles/` — 전체 변환됨

---

## 변환 대상 (이번 작업 범위)

| ERB 파일 | Phlex 클래스 | 비고 |
|---|---|---|
| `layouts/application.html.erb` | `Views::Layouts::Application` | `Phlex::Rails::Layout` 상속 |
| `articles/show.html.erb` | `Views::Articles::Show` | `Views::Base` 상속 |
| `home/about.html.erb` | `Views::Home::About` | `Views::Base` 상속 |
| `passwords/new.html.erb` | `Views::Passwords::New` | `Views::Base` 상속 |
| `passwords/edit.html.erb` | `Views::Passwords::Edit` | `Views::Base` 상속 |

## 변환 제외 대상

| 파일 | 이유 |
|---|---|
| `comments/create.turbo_stream.erb` | turbo_stream 포맷, 내부 이미 Phlex 렌더링 |
| `comments/destroy.turbo_stream.erb` | 동일 |
| `pwa/manifest.json.erb` | JSON 템플릿 |
| `passwords_mailer/*.erb` | ActionMailer 템플릿 |
| `layouts/mailer*.erb` | ActionMailer 레이아웃 |
| `federails/client/**/*.erb` | 제거 예정 |
| `layouts/federails/application.html.erb` | 제거 예정 |

---

## 아키텍처

### 레이아웃: `Views::Layouts::Application`

**파일:** `app/views/layouts/application.rb`
**상속:** `Phlex::Rails::Layout`

Rails는 `layout "application"` 설정 시 `Views::Layouts::Application`을 자동으로 찾는다.
기존 `layouts/application.html.erb`는 변환 완료 후 삭제한다.
(컨트롤러에 명시적 `layout` 지시문 없음 — Rails 기본값으로 동작)

**`Views::Layouts::Application`은 `Phlex::Rails::Layout`을 직접 상속하므로 `Components::Base`를 거치지 않는다.
모든 헬퍼를 명시적으로 include해야 한다:**
- `Phlex::Rails::Helpers::ContentFor` — content_for 블록 지원
- `Phlex::Rails::Helpers::CsrfMetaTags` — csrf_meta_tags
- `Phlex::Rails::Helpers::CspMetaTag` — csp_meta_tag
- `Phlex::Rails::Helpers::StylesheetLinkTag` — stylesheet_link_tag
- `Phlex::Rails::Helpers::JavascriptImportmapTags` — javascript_importmap_tags
- `Phlex::Rails::Helpers::FormWith` — form_with (nav 검색 폼)
- `Phlex::Rails::Helpers::LinkTo` — link_to
- `Phlex::Rails::Helpers::ImageUrl` — image_url (og image)
- `Phlex::Rails::Helpers::Routes` — 모든 path/url 헬퍼
- `PhlexIcons` — phlex_icon 헬퍼 (아이콘 사용 시 필수; 기존 뷰들도 직접 include 중)

**`render(Component.new)` — Phlex render (ERB의 `<%= render %>` 와 다름, 단순 `render(...)` 사용)**

**meta-tags gem 패턴:**
레이아웃에서 `helpers.display_meta_tags(...)` 형태로 ActionView helpers 프록시를 통해 호출.
`set_meta_tags`도 동일하게 `helpers.set_meta_tags(...)`.

**authenticated?, Current.user:**
컴포넌트/뷰에서는 `view_context.authenticated?` 패턴 사용 (기존 컴포넌트 코드 참고).
레이아웃(`Phlex::Rails::Layout`)에서도 동일하게 `helpers.authenticated?` 또는 `view_context.authenticated?` 사용.
`Current.user`는 Current 모델 직접 접근.

**nav_link_to 커스텀 헬퍼:**
ApplicationHelper에 정의됨. `helpers.nav_link_to(...)` 로 호출.

**Phlex 렌더 문법 주의:**
ERB에서 `<%= render Components::Flash.new %>` → Phlex에서 `render(Components::Flash.new)` (= 불필요)

**HTML 구조:**
```
doctype
html(lang: I18n.locale)
  head
    - Google Analytics script (gtag.js) — raw_html 또는 unsafe_raw 사용
    - Microsoft Clarity script — 동일
    - viewport / mobile meta tags
    - helpers.set_meta_tags(canonical: ...)
    - helpers.display_meta_tags(title:, description:, og:, article:, twitter:)
    - RSS alternate link
    - csrf_meta_tags, csp_meta_tag
    - yield_content(:head) — 각 뷰의 content_for(:head) 삽입
    - PWA manifest link
    - favicon links
    - Google Fonts preconnect + preload + stylesheet
    - stylesheet_link_tag :app
    - javascript_importmap_tags
    - unsafe_raw(@web_site.to_s) if @web_site
    - unsafe_raw(@news_media_organization.to_s) if @news_media_organization
  body(class: ..., data: {...})
    - a(href: "#main-content", class: "sr-only ...") — skip link
    - loading indicator div (page-loader Stimulus)
    - nav(...) — 로고, 모바일 토글, 메뉴 items, 검색 form_with, 인증 링크
    - main(id: "main-content", class: ...)
        - if helpers.authenticated? && WebPushConfig.configured?
            push notifications div (data-controller 등)
            render(Components::PushNotifications::PromptModal.new)
        - render(Components::Flash.new)
        - yield_content — 페이지 본문
    - footer — copyright, social links (Mastodon, X, RSS)
```

**인라인 JavaScript 처리:**
Google Analytics, Clarity 같은 인라인 스크립트는 Phlex의 `unsafe_raw(...)` 또는
`script { unsafe_raw "..." }` 패턴으로 처리.

---

### 레이아웃에서 사용하는 인스턴스 변수 (컨트롤러 제공)

| 변수 | 제공 위치 | 레이아웃 사용 |
|---|---|---|
| `@web_site` | ApplicationController before_action | head schema |
| `@news_media_organization` | HomeController, ArticlesController | head schema |
| `@page_description` | ArticlesController | meta description |
| `@og_type` | ArticlesController | og:type |
| `@og_article` | ArticlesController | article: meta |
| `@news_article` | ArticlesController | content_for(:head)에서 view가 삽입 |
| `@breadcrumbs` | ArticlesController | content_for(:head)에서 view가 삽입 |

`@news_article`, `@breadcrumbs`는 뷰에서 `content_for(:head)` 블록 안에 삽입 — 레이아웃이 직접 접근하지 않음.

---

### 페이지 뷰

#### `Views::Articles::Show`
**파일:** `app/views/articles/show.rb`

```ruby
include Phlex::Rails::Helpers::ContentFor
include Phlex::Rails::Helpers::LinkTo
include Phlex::Rails::Helpers::Sanitize

def initialize(article:, comments:, comment:, similar_articles:)
```

**구조:**
- `content_for(:title)` — `article.title_ko`
- `content_for(:head)` — `@news_article`, `@breadcrumbs` raw 삽입
- 아티클 헤더 (제목, 원문 언어 제목, 메타데이터, 원문 링크)
- 핵심 요약 섹션 (summary_key 배열 렌더링)
- 상세 내용 섹션 (introduction / body / conclusion)
- 관련 글 섹션 (similar_articles 있을 때)
- 댓글 섹션 (CommentForm, Comments 컴포넌트 렌더링)

**주의:**
- `sanitize Kramdown::Document.new(...).to_html` → `helpers.sanitize(...)` 또는 `Phlex::Rails::Helpers::Sanitize` include 후 `sanitize(...)`
- `phlex_icon` 직접 호출 가능 (Components::Base 상속)
- `render(RubyUI::Heading.new(...))` — Phlex 문법
- `dom_id(@article)` → `helpers.dom_id(@article)`

#### `Views::Home::About`
**파일:** `app/views/home/about.rb`

```ruby
include Phlex::Rails::Helpers::ContentFor

def initialize; end  # 또는 initialize 생략
```

- `content_for(:title)` — "소개 | Ruby-News"
- `content_for(:head)` — description meta tag
- 정적 콘텐츠 (서비스 소개, 콘텐츠 제작 방식, 큐레이션 기준, 연락처)

#### `Views::Passwords::New`
**파일:** `app/views/passwords/new.rb`

```ruby
include Phlex::Rails::Helpers::ContentFor
include Phlex::Rails::Helpers::FormWith

def initialize; end
```

비밀번호 재설정 요청 폼.

#### `Views::Passwords::Edit`
**파일:** `app/views/passwords/edit.rb`

```ruby
include Phlex::Rails::Helpers::ContentFor
include Phlex::Rails::Helpers::FormWith

def initialize(token:)
```

새 비밀번호 설정 폼. `password_path(token)` URL 생성에 token 사용.

---

## 컨트롤러 수정

### `ArticlesController#show`

```ruby
def show
  # ... 기존 인스턴스 변수 설정 코드 유지 (변경 없음) ...
  @comment = Comment.new
  render Views::Articles::Show.new(
    article: @article,
    comments: @comments,
    comment: @comment,
    similar_articles: @similar_articles
  )
end
```

### `HomeController#about`

```ruby
def about
  cacheable_page!
  render Views::Home::About.new
end
```

### `PasswordsController#new` / `#edit`

```ruby
def new
  render Views::Passwords::New.new
end

def edit
  render Views::Passwords::Edit.new(token: params[:token])
end
```

---

## 구현 순서

1. `Views::Layouts::Application` 작성
2. 레이아웃 최소 동작 확인 (기존 ERB 뷰 하나로 렌더링 테스트)
3. ERB 레이아웃 (`layouts/application.html.erb`) 삭제
4. `Views::Home::About` 작성 + `HomeController#about` 수정
5. `Views::Passwords::New` 작성 + 컨트롤러 수정
6. `Views::Passwords::Edit` 작성 + 컨트롤러 수정
7. `Views::Articles::Show` 작성 + `ArticlesController#show` 수정
8. 전체 동작 확인 후 ERB 파일들 삭제

---

## 리스크 및 고려사항

- **meta-tags gem**: `helpers.display_meta_tags(...)`, `helpers.set_meta_tags(...)` 패턴 사용
- **인라인 JS**: `script { unsafe_raw "..." }` 패턴으로 Analytics/Clarity 스크립트 처리
- **content_for**: 각 뷰에서 `content_for(:title)`, `content_for(:head)` 사용; 레이아웃에서 `yield_content(:head)` 로 렌더링
- **인스턴스 변수**: 컨트롤러 인스턴스 변수(`@web_site` 등)는 Phlex 레이아웃에서도 직접 접근 가능
- **authenticated?**: `helpers.authenticated?` 또는 `view_context.authenticated?` 로 호출 (기존 컴포넌트 코드는 `view_context.authenticated?` 패턴 사용); `Current.user`는 직접 접근
- **PhlexIcons**: 아이콘 사용하는 모든 뷰/레이아웃에 `include PhlexIcons` 명시 필요 (자동 상속 안 됨)
- **nav_link_to**: `helpers.nav_link_to(...)` 로 호출
- **render 문법**: Phlex에서 컴포넌트 렌더는 `render(Component.new)` — ERB의 `<%= render %>` 와 다름
- **dom_id**: `helpers.dom_id(@article)` 로 호출
- **sanitize**: `Phlex::Rails::Helpers::Sanitize` include 후 직접 호출 또는 `helpers.sanitize(...)`
