# ERB → Phlex 뷰 변환 설계

**날짜:** 2026-03-18
**브랜치:** feature/rubyui

---

## 목표

`app/views/` 디렉토리에 남아 있는 HTML ERB 템플릿을 Phlex 뷰 컴포넌트로 전환한다.
madmin, federails, mailer, JSON 템플릿은 변환하지 않는다.

---

## 변환 대상

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

**포함 헬퍼:**
- `Phlex::Rails::Helpers::ContentFor`
- `Phlex::Rails::Helpers::CsrfMetaTags`
- `Phlex::Rails::Helpers::CspMetaTag`
- `Phlex::Rails::Helpers::StylesheetLinkTag`
- `Phlex::Rails::Helpers::JavascriptImportmapTags`
- `Phlex::Rails::Helpers::FormWith`
- Routes, ImageUrl, LinkTo 등 기존 `Components::Base`에서 상속되는 헬퍼들

**HTML 구조:**
```
doctype
html(lang: I18n.locale)
  head
    - Google Analytics (gtag.js)
    - Microsoft Clarity
    - viewport / mobile meta tags
    - set_meta_tags / display_meta_tags (meta-tags gem)
    - RSS alternate link
    - csrf_meta_tags, csp_meta_tag
    - content_for(:head) yield
    - PWA manifest link
    - favicon links
    - Google Fonts preconnect + preload + stylesheet
    - stylesheet_link_tag :app
    - javascript_importmap_tags
    - @web_site, @news_media_organization schema
  body
    - skip link (accessibility)
    - loading indicator (page-loader Stimulus)
    - nav (logo, mobile toggle, menu items, search form, auth links)
    - main#main-content
        - push notifications div (if authenticated && WebPushConfig.configured?)
        - render Components::Flash.new
        - yield (페이지 콘텐츠)
    - footer (copyright, social links)
```

**주의사항:**
- `display_meta_tags`와 `set_meta_tags`는 `meta-tags` gem helper로, `helpers.display_meta_tags(...)` 또는 `helpers` 프록시를 통해 호출
- `phlex_icon` 헬퍼는 `Components::Base`에서 이미 사용 가능
- `nav_link_to` 커스텀 헬퍼도 include 필요

---

### 페이지 뷰

#### `Views::Articles::Show`
**파일:** `app/views/articles/show.rb`

```ruby
def initialize(article:, comments:, comment:, similar_articles:)
```

**구조:**
- `content_for :title`, `content_for :head` (@news_article, @breadcrumbs 는 컨트롤러에서 인스턴스변수로 레이아웃에 노출)
- 아티클 헤더 (제목, 메타데이터, 원문 링크)
- 핵심 요약 섹션 (summary_key)
- 상세 내용 섹션 (도입/본문/결론)
- 관련 글 섹션 (similar_articles)
- 댓글 섹션 (CommentForm, Comments 컴포넌트 렌더링)

**주의:** `sanitize Kramdown::Document.new(...).to_html` — `helpers.sanitize(...)` 사용

#### `Views::Home::About`
**파일:** `app/views/home/about.rb`

```ruby
def initialize; end
```

단순 정적 콘텐츠. `content_for :title`, `content_for :head` 포함.

#### `Views::Passwords::New`
**파일:** `app/views/passwords/new.rb`

```ruby
def initialize; end
```

비밀번호 재설정 요청 폼. `form_with`, `RubyUI::Button` 렌더링.

#### `Views::Passwords::Edit`
**파일:** `app/views/passwords/edit.rb`

```ruby
def initialize(token:)
```

새 비밀번호 설정 폼. token은 form action URL 생성에 사용.

---

## 컨트롤러 수정

### `ArticlesController`

```ruby
def show
  # ... 기존 인스턴스 변수 설정 유지 ...
  @comment = Comment.new
  render Views::Articles::Show.new(
    article: @article,
    comments: @comments,
    comment: @comment,
    similar_articles: @similar_articles
  )
end
```

### `HomeController`

```ruby
def about
  cacheable_page!
  render Views::Home::About.new
end
```

### `PasswordsController`

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

1. `Views::Layouts::Application` 작성 (레이아웃)
2. ERB 레이아웃 삭제
3. `Views::Home::About` 작성 + 컨트롤러 수정
4. `Views::Passwords::New` 작성 + 컨트롤러 수정
5. `Views::Passwords::Edit` 작성 + 컨트롤러 수정
6. `Views::Articles::Show` 작성 + 컨트롤러 수정
7. 동작 확인

---

## 리스크 및 고려사항

- **meta-tags gem 헬퍼**: `display_meta_tags`, `set_meta_tags`는 ActionView 헬퍼이므로 Phlex에서 `helpers.` 프록시 또는 직접 include 필요
- **`content_for(:head)`**: 각 뷰에서 `content_for :head do ... end` 블록을 사용하여 레이아웃의 head에 삽입
- **`@web_site`, `@news_media_organization`**: 컨트롤러 인스턴스 변수 그대로 레이아웃에서 접근 (`@web_site`)
- **`yield :head`**: Phlex 레이아웃에서 `content_for(:head)` 렌더링은 `yield_content(:head)` 사용
- **인증 관련**: `authenticated?`, `Current.user` — ApplicationHelper에 있으므로 레이아웃에서 `helpers.authenticated?` 또는 직접 include
