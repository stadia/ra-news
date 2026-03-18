# ERB → Phlex 뷰 변환 구현 계획

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 남아 있는 5개의 HTML ERB 뷰 파일과 application 레이아웃을 Phlex 뷰 컴포넌트로 전환한다.

**Architecture:** `Phlex::Rails::Layout`을 상속하는 `Views::Layouts::Application`을 생성하여 ERB 레이아웃을 대체한다. 각 페이지 뷰는 `Views::Base`를 상속하는 Phlex 컴포넌트로 변환하고 컨트롤러에서 `render Views::*.new(...)` 형태로 호출한다. Rails는 view를 먼저 렌더링 후 layout을 적용하므로, layout에서 `helpers.content_for(:title)` 호출 시 view가 설정한 값이 이미 반영된 상태다.

**Tech Stack:** Ruby on Rails 8, Phlex 2.x, Phlex::Rails, PhlexIcons (`include PhlexIcons`로 `phlex_icon` 헬퍼 활성화), RubyUI, Minitest ActionDispatch integration tests

---

## 파일 목록

**생성:**
- `app/views/layouts/application.rb` — Phlex 레이아웃
- `app/views/home/about.rb` — About 페이지 뷰
- `app/views/passwords/new.rb` — 비밀번호 재설정 요청 뷰
- `app/views/passwords/edit.rb` — 새 비밀번호 설정 뷰
- `app/views/articles/show.rb` — 아티클 상세 뷰
- `test/controllers/home_controller_test.rb`
- `test/controllers/passwords_controller_test.rb`
- `test/controllers/articles_controller_test.rb`

**수정:**
- `app/controllers/home_controller.rb` — about 액션에 render 추가
- `app/controllers/passwords_controller.rb` — new, edit 액션에 render 추가
- `app/controllers/articles_controller.rb` — show 액션에 render 추가

**삭제 (단계별):**
- `app/views/layouts/application.html.erb`
- `app/views/home/about.html.erb`
- `app/views/passwords/new.html.erb`
- `app/views/passwords/edit.html.erb`
- `app/views/articles/show.html.erb`

---

## 공통 패턴 참고

Phlex 뷰에서 헬퍼 호출 패턴:
- `helpers.authenticated?` — ApplicationController 헬퍼
- `helpers.nav_link_to(...)` — ApplicationHelper 커스텀 헬퍼
- `helpers.content_for(:title)` — layout에서 view가 설정한 title 읽기
- `helpers.content_for(:head)` — layout에서 view가 설정한 head 읽기
- `unsafe_raw helpers.display_meta_tags(...)` — meta-tags gem 출력
- `unsafe_raw helpers.csrf_meta_tags` — CSRF 메타태그
- `unsafe_raw helpers.csp_meta_tag` — CSP 메타태그
- `helpers.dom_id(record)` — DOM ID 생성
- `helpers.sanitize(html_string)` — HTML 살균
- `render(Component.new)` — Phlex 컴포넌트 렌더 (ERB의 `<%= render %>` 와 다름)

---

## Task 1: Application Layout

**Files:**
- Create: `app/views/layouts/application.rb`
- Delete: `app/views/layouts/application.html.erb`

- [ ] **Step 1: 레이아웃 파일 생성**

```ruby
# app/views/layouts/application.rb
# frozen_string_literal: true

class Views::Layouts::Application < Phlex::Rails::Layout
  include PhlexIcons
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::StylesheetLinkTag
  include Phlex::Rails::Helpers::JavascriptImportmapTags
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageUrl
  include Phlex::Rails::Helpers::Routes

  def view_template
    doctype
    html(lang: I18n.locale) do
      head { render_head }
      body(
        class: "bg-slate-900 text-slate-200 min-h-screen flex flex-col",
        data: {
          controller: "page-loader",
          action: "turbo:before-visit@window->page-loader#beforeTurboVisit turbo:load@window->page-loader#afterTurboLoad"
        }
      ) do
        render_skip_link
        render_loader
        render_nav
        main(id: "main-content", class: "container mx-auto px-4 py-8 grow") do
          render_push_notifications
          render(Components::Flash.new)
          yield_content
        end
        render_footer
      end
    end
  end

  private

  def render_head
    # Google Analytics
    script(async: true, src: "https://www.googletagmanager.com/gtag/js?id=G-56PSNXG7QG")
    script do
      unsafe_raw <<~JS
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-56PSNXG7QG');
      JS
    end

    # Microsoft Clarity
    script(type: "text/javascript") do
      unsafe_raw <<~JS
        (function(c,l,a,r,i,t,y){
            c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
            t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
            y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
        })(window, document, "clarity", "script", "u4rt68vefo");
      JS
    end

    meta(name: "viewport", content: "width=device-width,initial-scale=1,viewport-fit=cover")
    meta(name: "apple-mobile-web-app-capable", content: "yes")
    meta(name: "mobile-web-app-capable", content: "yes")
    meta(name: "apple-mobile-web-app-status-bar-style", content: "black-translucent")

    helpers.set_meta_tags(canonical: "https://ruby-news.kr#{helpers.request.path}")
    unsafe_raw helpers.display_meta_tags(
      title: helpers.content_for(:title).presence || "Ruby-News | 루비 AI 뉴스",
      description: @page_description || "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요",
      og: {
        title: helpers.content_for(:title).presence || "Ruby-News | 루비 AI 뉴스",
        description: @page_description || "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요",
        site_name: "Ruby-News | 루비 AI 뉴스",
        image: image_url("og_main.png"),
        type: @og_type || "website",
        url: "https://ruby-news.kr#{helpers.request.path}",
        locale: "ko_KR"
      },
      article: @og_article,
      twitter: {
        card: "summary_large_image",
        site: "@rubynewskr",
        title: helpers.content_for(:title).presence || "Ruby-News | 루비 AI 뉴스",
        description: @page_description || "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요",
        image: image_url("og_main.png")
      }
    )

    link(rel: "alternate", type: "application/rss+xml", title: "Ruby-News RSS 피드", href: "/rss")
    unsafe_raw helpers.csrf_meta_tags
    unsafe_raw helpers.csp_meta_tag
    unsafe_raw helpers.content_for(:head)

    link(rel: "manifest", href: helpers.pwa_manifest_path(format: :json))
    link(rel: "icon", href: "/icon.png", type: "image/png")
    link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
    link(rel: "apple-touch-icon", href: "/icon.png")

    link(rel: "preconnect", href: "https://fonts.googleapis.com")
    link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
    link(
      rel: "preload",
      href: "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap",
      as: "style"
    )
    link(
      rel: "stylesheet",
      href: "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap"
    )

    unsafe_raw stylesheet_link_tag(:app, "data-turbo-track": "reload")
    unsafe_raw javascript_importmap_tags
    unsafe_raw @web_site.to_s if @web_site
    unsafe_raw @news_media_organization.to_s if @news_media_organization
  end

  def render_skip_link
    a(
      href: "#main-content",
      class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-green-500 focus:text-white focus:rounded-lg focus:shadow-lg"
    ) { "본문으로 건너뛰기" }
  end

  def render_loader
    div(
      data: { "page-loader-target": "loader" },
      class: "fixed inset-0 bg-slate-900 bg-opacity-75 z-50 hidden items-center justify-center"
    ) do
      div(class: "flex flex-col items-center space-y-4") do
        div(class: "animate-spin rounded-full h-12 w-12 border-4 border-green-500 border-t-transparent shadow-lg shadow-green-500/50")
        div(class: "text-white font-medium") { "로딩 중..." }
      end
    end
  end

  def render_nav
    nav(
      class: "bg-slate-800 border-b border-slate-700 border-t-4 border-t-green-500",
      aria: { label: "주 네비게이션" }
    ) do
      div(class: "max-w-7xl flex flex-wrap items-center justify-between mx-auto p-4") do
        link_to(root_path, class: "flex items-center space-x-3 rtl:space-x-reverse group") do
          span(class: "self-center text-2xl font-semibold whitespace-nowrap text-white group-hover:text-green-400 transition-colors duration-200") do
            plain "Ruby-News || "
            span(class: "text-green-400") { "루비 AI 뉴스" }
          end
        end

        input(type: "checkbox", id: "mobile-menu-toggle", class: "mobile-menu-toggle peer")
        label(
          for: "mobile-menu-toggle",
          class: "inline-flex items-center p-2 w-11 h-11 justify-center text-sm text-slate-100 rounded-lg md:hidden hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-800 cursor-pointer",
          aria: { label: "메뉴 열기/닫기" }
        ) do
          span(class: "sr-only") { "Open main menu" }
          phlex_icon "bars-3", variant: :outline, class: "w-5 h-5 transition-transform duration-200 peer-checked:rotate-45"
        end

        div(
          class: "items-center justify-between w-full md:flex md:w-auto md:order-1 hidden peer-checked:block transition-all duration-300 ease-in-out md:transition-none",
          id: "navbar-search"
        ) do
          ul(class: "flex flex-col p-4 md:p-0 mt-4 font-medium border border-slate-700 rounded-lg bg-slate-700 md:space-x-8 rtl:space-x-reverse md:flex-row md:mt-0 md:border-0 md:bg-slate-800 animate-in slide-in-from-top-2 fade-in duration-200 md:animate-none") do
            li { unsafe_raw helpers.nav_link_to("홈", root_path) }
            li { unsafe_raw helpers.nav_link_to("지난 글", articles_path) }
            li { unsafe_raw helpers.nav_link_to("그 밖의 뉴스", others_path) }
            li(class: "flex items-center") do
              form_with(url: articles_path, method: :get, local: true, role: "search", aria: { label: "기사 검색" }, class: "flex items-center space-x-2") do |f|
                f.text_field :search,
                  placeholder: "검색...",
                  value: helpers.params[:search],
                  class: "px-3 py-2 text-sm text-slate-100 bg-slate-700 border border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent w-40 md:w-48 transition-all duration-200"
                render RubyUI::Button.new(
                  type: "submit",
                  variant: :primary,
                  size: :lg,
                  class: "font-medium bg-green-500 rounded-lg border border-green-500 hover:bg-green-600 focus:ring-2 focus:outline-none focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-800 transition-all duration-150 min-h-11 cursor-pointer"
                ) { "검색" }
              end
            end
            if helpers.authenticated?
              li { unsafe_raw helpers.nav_link_to("글 등록", new_article_path) }
              li { unsafe_raw helpers.nav_link_to(Current.user.name, users_path) }
            end
            li do
              if helpers.authenticated?
                unsafe_raw helpers.nav_link_to("로그아웃", logout_path)
              else
                unsafe_raw helpers.nav_link_to("로그인", new_session_path)
              end
            end
          end
        end
      end
    end
  end

  def render_push_notifications
    return unless helpers.authenticated? && WebPushConfig.configured?

    div(
      data: {
        controller: "push-notifications",
        "push-notifications-public-key-value": WebPushConfig.public_key,
        "push-notifications-subscription-url-value": helpers.push_subscription_path,
        "push-notifications-service-worker-path-value": helpers.pwa_service_worker_path(format: :js),
        "push-notifications-cooldown-hours-value": "1"
      }
    ) do
      render(Components::PushNotifications::PromptModal.new)
    end
  end

  def render_footer
    footer(class: "bg-slate-800 text-slate-200 rounded-lg shadow-sm m-4 border border-slate-700 border-t-2 border-t-green-500") do
      div(class: "w-full mx-auto max-w-7xl p-4 md:flex md:items-center md:justify-between") do
        span(class: "text-sm text-slate-300 sm:text-center") do
          plain "© 2025 "
          a(href: "https://ruby-news.kr/", class: "hover:underline hover:text-white transition-colors duration-200") { "Ruby-News || 루비 AI 뉴스" }
          plain ". All Rights Reserved."
        end
        ul(class: "flex flex-wrap items-center mt-3 text-sm font-medium text-slate-300 sm:mt-0 gap-4") do
          li do
            a(rel: "me", href: "https://ruby.social/@news_kr", target: "_blank", class: "hover:underline hover:text-white flex items-center gap-1") do
              unsafe_raw '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.056.056 0 0 1 .017-.043.051.051 0 0 1 .043-.017c1.513.359 3.072.538 4.657.546 1.828 0 2.298-.081 3.09-.143 1.897-.149 3.566-.867 3.772-1.531.334-1.076.61-3.495.61-3.495 0-.732-.005-1.603-.05-2.447-.041-.832-.126-1.62-.333-2.377z"/></svg>'
              plain "Mastodon"
            end
          end
          li do
            a(href: "https://x.com/rubynewskr", target: "_blank", rel: "noopener noreferrer", class: "hover:underline hover:text-white flex items-center gap-1") do
              unsafe_raw '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>'
              plain "Twitter/X"
            end
          end
          li do
            a(href: helpers.rss_path, target: "_blank", rel: "noopener noreferrer", class: "hover:underline hover:text-white flex items-center gap-1") do
              phlex_icon "rss", variant: :outline, class: "w-5 h-5"
              plain "RSS 피드"
            end
          end
        end
      end
    end
  end
end
```

**참고:** `nav_link_to` 헬퍼는 HTML 문자열을 반환하므로 `unsafe_raw helpers.nav_link_to(...)` 패턴으로 렌더링.

- [ ] **Step 2: 컨트롤러 테스트 작성 (레이아웃 동작 확인용)**

```ruby
# test/controllers/home_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders layout with nav" do
    get root_path
    assert_response :success
    assert_select "nav"
    assert_select "footer"
    assert_select "main#main-content"
  end

  test "GET about returns 200" do
    get about_path
    assert_response :success
  end
end
```

- [ ] **Step 3: 테스트 실행 — 실패 확인 (about는 ERB가 아직 있으므로 통과, nav는 ERB 레이아웃)**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: root 테스트는 pass (ERB 레이아웃 있음), about 테스트는 pass (ERB 뷰 있음)

- [ ] **Step 4: ERB 레이아웃 삭제 (git rm 사용하여 git 추적 유지)**

```bash
git rm app/views/layouts/application.html.erb
```

- [ ] **Step 5: 테스트 재실행 — 새 Phlex 레이아웃으로 동작 확인**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: 2 tests pass. 실패 시 — 에러 메시지를 보고 헬퍼 include 또는 문법 수정.
일반적인 트러블슈팅:
- `NoMethodError: undefined method 'display_meta_tags'` → `helpers.display_meta_tags(...)` 확인
- `NameError: uninitialized constant Views::Layouts::Application` → 파일명/클래스명 확인
- `RuntimeError: unsafe_raw` 관련 → HTML 문자열을 `unsafe_raw(str)` 로 wrap

- [ ] **Step 6: 커밋**

```bash
git add app/views/layouts/application.rb test/controllers/home_controller_test.rb
git commit -m "feat: replace ERB application layout with Phlex Views::Layouts::Application"
```

---

## Task 2: Views::Home::About

**Files:**
- Create: `app/views/home/about.rb`
- Modify: `app/controllers/home_controller.rb`
- Delete: `app/views/home/about.html.erb`

- [ ] **Step 1: 테스트에 about 내용 검증 추가**

`test/controllers/home_controller_test.rb` 의 existing about test에 내용 검증 추가:

```ruby
test "GET about renders introduction content" do
  get about_path
  assert_response :success
  assert_select "h1", text: /Ruby-News 소개/
end
```

- [ ] **Step 2: 테스트 실행 — 실패 확인 (ERB 뷰 있지만 h1 내용 불일치 가능)**

```bash
bin/rails test test/controllers/home_controller_test.rb -n test_GET_about_renders_introduction_content
```

- [ ] **Step 3: Phlex 뷰 생성**

```ruby
# app/views/home/about.rb
# frozen_string_literal: true

class Views::Home::About < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def view_template
    content_for(:title, "소개 | Ruby-News")
    content_for(:head) do
      unsafe_raw '<meta name="description" content="Ruby-News는 Ruby·Rails 생태계 소식을 AI 보조 번역으로 매일 한국어로 제공하는 기술 뉴스 집약 서비스입니다.">'
    end

    div(class: "max-w-3xl mx-auto space-y-10") do
      header(class: "border-b border-slate-700 pb-8") do
        render RubyUI::Heading.new(level: 1, class: "font-bold text-white mb-3") { "Ruby-News 소개" }
        p(class: "text-lg text-slate-300") do
          plain "Ruby·Rails 생태계 소식을 AI 보조 번역으로 매일 한국어로 제공하는 기술 뉴스 집약 서비스입니다."
        end
      end

      section(class: "space-y-4") do
        render RubyUI::Heading.new(level: 2, class: "font-semibold text-green-400 mb-3") { "서비스 소개" }
        p(class: "text-slate-300 leading-relaxed") do
          plain "Ruby-News는 전 세계 Ruby 및 Ruby on Rails 커뮤니티에서 발행되는 기술 아티클, 릴리즈 노트, 보안 권고, 컨퍼런스 자료를 매일 수집하여 한국어로 번역·요약합니다. 한국어권 Ruby 개발자가 언어 장벽 없이 최신 생태계 동향을 파악할 수 있도록 만들어졌습니다."
        end
        ul(class: "text-slate-300 space-y-1 list-disc list-inside") do
          li { "누적 기사 2,400개 이상 — 매일 업데이트" }
          li { "Ruby 버전 릴리즈, Rails 업그레이드 가이드, CVE 보안 권고" }
          li { "RubyGems 신규 릴리즈, 성능 최적화, Hotwire·Turbo 패턴" }
          li { "RubyKaigi, Rails World 등 커뮤니티 행사 소식" }
        end
      end

      section(class: "space-y-4") do
        render RubyUI::Heading.new(level: 2, class: "font-semibold text-green-400 mb-3") { "콘텐츠 제작 방식" }
        p(class: "text-slate-300 leading-relaxed") do
          plain "모든 기사는 "
          strong(class: "text-slate-100") { "AI 보조 번역" }
          plain "을 통해 제작됩니다. 원문 영어 아티클을 AI가 한국어로 번역하고 핵심 내용을 3개 요점으로 요약합니다. 각 기사 페이지에는 원문 출처 URL이 명시되어 있으며, 독자가 원문을 직접 확인할 수 있습니다."
        end
        p(class: "text-slate-300 leading-relaxed") do
          plain "번역의 정확성을 위해 노력하지만, AI 번역의 특성상 오역이 있을 수 있습니다. 중요한 기술적 판단에는 반드시 원문을 함께 참고하시기 바랍니다."
        end
      end

      section(class: "space-y-4") do
        render RubyUI::Heading.new(level: 2, class: "font-semibold text-green-400 mb-3") { "큐레이션 기준" }
        p(class: "text-slate-300 leading-relaxed") do
          plain "Ruby·Rails 생태계에 직접적으로 관련된 콘텐츠를 중심으로 수집합니다. ruby-lang.org, rubyonrails.org, RubyGems, thoughtbot, Evil Martians, HackerNews, YouTube 기술 채널 등 신뢰할 수 있는 출처를 우선합니다."
        end
      end

      section(class: "space-y-4") do
        render RubyUI::Heading.new(level: 2, class: "font-semibold text-green-400 mb-3") { "연락처" }
        ul(class: "text-slate-300 space-y-2") do
          li do
            plain "Mastodon: "
            a(href: "https://ruby.social/@news_kr", rel: "me", target: "_blank", class: "text-green-400 hover:underline") { "@news_kr@ruby.social" }
          end
          li do
            plain "Twitter/X: "
            a(href: "https://x.com/rubynewskr", target: "_blank", rel: "noopener noreferrer", class: "text-green-400 hover:underline") { "@rubynewskr" }
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: 컨트롤러 수정**

`app/controllers/home_controller.rb` 의 `about` 액션 수정:

```ruby
def about
  cacheable_page!
  render Views::Home::About.new
end
```

- [ ] **Step 5: ERB 뷰 삭제**

```bash
rm app/views/home/about.html.erb
```

- [ ] **Step 6: 테스트 실행**

```bash
bin/rails test test/controllers/home_controller_test.rb
```

Expected: all pass

- [ ] **Step 7: 커밋**

```bash
git add app/views/home/about.rb app/controllers/home_controller.rb
git rm app/views/home/about.html.erb
git add test/controllers/home_controller_test.rb
git commit -m "feat: convert home/about ERB to Views::Home::About Phlex component"
```

---

## Task 3: Views::Passwords::New

**Files:**
- Create: `app/views/passwords/new.rb`
- Create: `test/controllers/passwords_controller_test.rb`
- Modify: `app/controllers/passwords_controller.rb`
- Delete: `app/views/passwords/new.html.erb`

- [ ] **Step 1: 테스트 작성**

```ruby
# test/controllers/passwords_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 with password reset form" do
    get new_password_path
    assert_response :success
    assert_select "h1", text: /비밀번호를 잊으셨나요/
    assert_select "input[type=email]"
  end

  test "GET edit with valid token returns 200" do
    user = users(:john)
    token = user.password_reset_token
    get edit_password_path(token)
    assert_response :success
    assert_select "input[type=password]"
  end
end
```

- [ ] **Step 2: 테스트 실행 — 현재 상태 확인**

```bash
bin/rails test test/controllers/passwords_controller_test.rb
```

Expected: pass (ERB 뷰 있음)

- [ ] **Step 3: Phlex 뷰 생성**

```ruby
# app/views/passwords/new.rb
# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "비밀번호를 잊으셨나요?" }

      form_with(url: helpers.passwords_path, class: "contents") do |f|
        div(class: "my-5") do
          f.email_field :email_address,
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "이메일 주소를 입력하세요",
            value: helpers.params[:email_address],
            class: "block shadow-sm rounded-md border border-slate-600 px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-green-500 hover:bg-green-600 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
          ) { "재설정 메일 보내기" }
        end
      end
    end
  end
end
```

- [ ] **Step 4: 컨트롤러 수정**

`app/controllers/passwords_controller.rb` 의 `new` 액션:

```ruby
def new
  render Views::Passwords::New.new
end
```

- [ ] **Step 5: ERB 삭제 후 테스트**

```bash
rm app/views/passwords/new.html.erb
bin/rails test test/controllers/passwords_controller_test.rb -n test_GET_new_returns_200_with_password_reset_form
```

Expected: pass

- [ ] **Step 6: 커밋 (edit도 함께 처리 후 커밋)**

다음 Task 완료 후 함께 커밋.

---

## Task 4: Views::Passwords::Edit

**Files:**
- Create: `app/views/passwords/edit.rb`
- Modify: `app/controllers/passwords_controller.rb`
- Delete: `app/views/passwords/edit.html.erb`

- [ ] **Step 1: Phlex 뷰 생성**

```ruby
# app/views/passwords/edit.rb
# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def initialize(token:)
    @token = token
  end

  def view_template
    div(class: "mx-auto md:w-2/3 w-full") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "새 비밀번호 설정" }

      form_with(url: helpers.password_path(@token), method: :put, class: "contents") do |f|
        div(class: "my-5") do
          f.password_field :password,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-slate-600 px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200"
        end

        div(class: "my-5") do
          f.password_field :password_confirmation,
            required: true,
            autocomplete: "new-password",
            placeholder: "새 비밀번호를 다시 입력하세요",
            maxlength: 72,
            class: "block shadow-sm rounded-md border border-slate-600 px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors duration-200"
        end

        div(class: "inline") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            size: :lg,
            class: "w-full sm:w-auto rounded-md bg-green-500 hover:bg-green-600 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
          ) { "저장" }
        end
      end
    end
  end
end
```

- [ ] **Step 2: 컨트롤러 수정**

`app/controllers/passwords_controller.rb` 의 `edit` 액션:

```ruby
def edit
  render Views::Passwords::Edit.new(token: params[:token])
end
```

- [ ] **Step 3: ERB 삭제 후 테스트 실행**

```bash
rm app/views/passwords/edit.html.erb
bin/rails test test/controllers/passwords_controller_test.rb
```

Expected: all pass

- [ ] **Step 4: 커밋**

```bash
git add app/views/passwords/new.rb app/views/passwords/edit.rb
git add app/controllers/passwords_controller.rb
git rm app/views/passwords/new.html.erb app/views/passwords/edit.html.erb
git add test/controllers/passwords_controller_test.rb
git commit -m "feat: convert passwords/new and passwords/edit ERB to Phlex views"
```

---

## Task 5: Views::Articles::Show

**Files:**
- Create: `app/views/articles/show.rb`
- Create: `test/controllers/articles_controller_test.rb`
- Modify: `app/controllers/articles_controller.rb`
- Delete: `app/views/articles/show.html.erb`

- [ ] **Step 1: 테스트 작성**

```ruby
# test/controllers/articles_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "GET show returns 200 with article title" do
    article = articles(:ruby_article)
    get article_path(article)
    assert_response :success
    assert_select "article"
    assert_select "h1", text: /#{Regexp.escape(article.title_ko)}/
  end
end
```

- [ ] **Step 2: 테스트 실행 — 현재 상태 확인**

```bash
bin/rails test test/controllers/articles_controller_test.rb
```

Expected: pass (ERB 뷰 있음)

- [ ] **Step 3: Phlex 뷰 생성**

```ruby
# app/views/articles/show.rb
# frozen_string_literal: true

class Views::Articles::Show < Views::Base
  include PhlexIcons
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Sanitize

  def initialize(article:, comments:, comment:, similar_articles:)
    @article = article
    @comments = comments
    @comment = comment
    @similar_articles = similar_articles
  end

  def view_template
    content_for(:title, @article.title_ko)

    # @news_article, @breadcrumbs 는 ArticlesController#show 에서 인스턴스 변수로 설정됨
    # layout의 yield_content(:head) 에 schema.org JSON-LD 마크업 삽입
    content_for(:head) do
      unsafe_raw @news_article.to_s if @news_article
      unsafe_raw @breadcrumbs.to_s if @breadcrumbs
    end

    div(class: "space-y-6 lg:space-y-8 max-w-6xl mx-auto", id: helpers.dom_id(@article)) do
      render_article_main
      render_similar_articles if @similar_articles.present?
      render_comments_section
    end
  end

  private

  def render_article_main
    article(class: "bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700") do
      render_article_header
      render_article_body
    end
  end

  def render_article_header
    header(class: "p-4 md:p-6 lg:p-8 border-b border-gray-700") do
      div(class: "mb-6") do
        render RubyUI::Heading.new(
          level: 1,
          class: "!text-2xl lg:!text-3xl font-bold text-gray-100 mb-4 leading-tight"
        ) { @article.title_ko }

        if @article.title_ko != @article.title
          render RubyUI::Heading.new(level: 2, class: "font-medium text-gray-300 mb-4") { @article.title }
        end
      end

      div(class: "flex flex-wrap items-center gap-4 md:gap-6 text-sm text-gray-300") do
        # 작성자
        div(class: "flex items-center") do
          div(class: "w-8 h-8 bg-green-600 rounded-full flex items-center justify-center mr-3") do
            phlex_icon "user", variant: :outline, class: "w-4 h-4 text-white"
          end
          div do
            div(class: "text-xs text-gray-300") { "작성자" }
            div(class: "font-medium text-gray-200") do
              render(Components::Articles::ArticleUser.new(article: @article))
            end
          end
        end

        # 발행일
        div(class: "flex items-center") do
          phlex_icon "calendar", variant: :outline, class: "w-5 h-5 mr-2 text-gray-500"
          div do
            div(class: "text-xs text-gray-300") { "발행일" }
            div(class: "font-medium text-gray-200") do
              time(datetime: @article.published_at&.iso8601) do
                plain @article.published_at&.strftime("%Y년 %m월 %d일") || "N/A"
              end
            end
          end
        end
      end

      # 원문 링크
      div(class: "mt-6 p-4 bg-gray-700 rounded-lg") do
        div(class: "flex items-center flex-1 min-w-0") do
          div(class: "w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center mr-3 shrink-0") do
            phlex_icon "arrow-top-right-on-square", variant: :outline, class: "w-5 h-5 text-white"
          end
          div(class: "min-w-0 flex-1") do
            div(class: "text-sm font-medium text-blue-300 group-hover:text-blue-200 transition-colors") do
              plain @article.url
            end
          end
        end
      end
    end
  end

  def render_article_body
    div(class: "p-4 md:p-6 lg:p-8") do
      # 핵심 요약
      section(class: "mb-8 lg:mb-12") do
        div(class: "bg-linear-to-r from-green-600 to-green-700 rounded-lg p-6") do
          render RubyUI::Heading.new(
            level: 2,
            class: "font-bold text-white mb-4 flex items-center"
          ) do
            phlex_icon "check-circle", variant: :outline, class: "w-6 h-6 mr-2"
            plain "핵심 요약"
          end

          if @article.summary_key.is_a?(Array)
            ul(class: "space-y-3") do
              @article.summary_key&.each_with_index do |item, index|
                li(class: "flex items-start") do
                  span(class: "shrink-0 w-6 h-6 bg-white bg-opacity-20 rounded-full flex items-center justify-center text-xs font-bold text-white mr-3 mt-0.5") do
                    plain (index + 1).to_s
                  end
                  span(class: "text-green-100 leading-relaxed") { plain item }
                end
              end
            end
          end
        end
      end

      # 상세 내용
      section(class: "prose prose-invert prose-lg max-w-none prose-headings:text-green-400 prose-strong:text-sky-300") do
        if @article.summary_detail.is_a?(Hash)
          # 도입부
          if @article.summary_detail["introduction"].present?
            div(class: "mb-8 p-6 bg-gray-700 rounded-xl border-l-4 border-blue-500") do
              render RubyUI::Heading.new(level: 3, class: "font-semibold text-blue-300 mb-3") { "도입" }
              div(class: "text-gray-200 leading-relaxed text-base") do
                plain @article.summary_detail["introduction"]
              end
            end
          end

          # 본문
          if @article.summary_body.present?
            div(class: "mb-8 article-content", id: "article-detail-body") do
              div(class: "prose prose-invert max-w-none prose-headings:text-green-400 prose-h1:text-2xl prose-h2:text-xl prose-h3:text-lg prose-h4:text-base prose-strong:text-sky-300 text-gray-200 leading-loose") do
                unsafe_raw sanitize(Kramdown::Document.new(@article.summary_body).to_html)
              end
            end
          end

          # 결론
          if @article.summary_detail["conclusion"].present?
            div(class: "p-6 bg-gray-700 rounded-xl border-l-4 border-green-500") do
              render RubyUI::Heading.new(level: 3, class: "font-semibold text-green-300 mb-3") { "결론" }
              div(class: "text-gray-200 leading-relaxed text-base") do
                plain @article.summary_detail["conclusion"]
              end
            end
          end
        end
      end
    end
  end

  def render_similar_articles
    section(class: "bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700") do
      div(class: "p-4 md:p-6 lg:p-8") do
        render RubyUI::Heading.new(level: 2, class: "font-bold text-gray-100 mb-6 flex items-center") do
          phlex_icon "newspaper", variant: :outline, class: "w-6 h-6 mr-2 text-green-500"
          plain "관련 글들"
        end

        div(class: "grid grid-cols-1 md:grid-cols-2 gap-4 lg:gap-6") do
          @similar_articles.each do |article|
            div(class: "group bg-gray-700 rounded-lg border border-gray-600 hover:border-gray-500 transition-all duration-200 overflow-hidden") do
              link_to(helpers.article_path(article), class: "block p-4 lg:p-6") do
                render RubyUI::Heading.new(
                  level: 3,
                  class: "font-semibold text-gray-100 group-hover:text-green-400 transition-colors duration-200 mb-3 line-clamp-2"
                ) { article.title_ko || article.title }

                p(class: "text-gray-200 text-sm leading-relaxed line-clamp-3 mb-4") do
                  plain(if article.summary_key.is_a?(String)
                    article.summary_key
                  else
                    article.summary_key&.first
                  end)
                end

                div(class: "flex items-center justify-between text-xs text-gray-300") do
                  span(class: "flex items-center") do
                    phlex_icon "calendar", variant: :outline, class: "w-4 h-4 mr-1"
                    plain article.published_at&.strftime("%m/%d")
                  end
                  span(class: "group-hover:text-green-400 transition-colors duration-200") { "읽어보기 →" }
                end
              end
            end
          end
        end
      end
    end
  end

  def render_comments_section
    section(class: "bg-gray-800 rounded-xl shadow-lg overflow-hidden border border-gray-700") do
      div(class: "p-4 md:p-6 lg:p-8") do
        render RubyUI::Heading.new(
          level: 3,
          class: "font-bold text-gray-100 mb-6 flex items-center",
          id: :comments_header
        ) { render(Components::Comments::CommentHeader.new(comments: @comments)) }

        div(id: "comment_form", class: "border-t border-gray-700 mb-4") do
          render(Components::Comments::CommentForm.new(article: @article, comment: @comment))
        end

        div(class: "space-y-4 pt-6") do
          render(Components::Comments::Comments.new(article: @article, comments: @comments))
        end
      end
    end
  end
end
```

- [ ] **Step 4: 컨트롤러 수정**

`app/controllers/articles_controller.rb` 의 `show` 액션 끝에 render 추가 (기존 인스턴스 변수 설정 코드는 그대로 유지):

```ruby
def show
  @comments = @article.comments.includes(:user)
  # ... (기존 @page_description, @og_type 등 설정 코드 유지) ...
  @comment = Comment.new
  render Views::Articles::Show.new(
    article: @article,
    comments: @comments,
    comment: @comment,
    similar_articles: @similar_articles
  )
end
```

- [ ] **Step 5: ERB 삭제 후 테스트**

```bash
rm app/views/articles/show.html.erb
bin/rails test test/controllers/articles_controller_test.rb
```

Expected: pass

- [ ] **Step 6: 커밋**

```bash
git add app/views/articles/show.rb app/controllers/articles_controller.rb
git rm app/views/articles/show.html.erb
git add test/controllers/articles_controller_test.rb
git commit -m "feat: convert articles/show ERB to Views::Articles::Show Phlex component"
```

---

## Task 6: 전체 테스트 및 최종 확인

- [ ] **Step 1: 전체 테스트 실행**

```bash
bin/rails test test/controllers/
```

Expected: all pass

- [ ] **Step 2: 남은 ERB 파일 확인 (변환 대상 파일이 모두 삭제됐는지 확인)**

```bash
find app/views -name "*.html.erb" | grep -v madmin | grep -v mailer | grep -v federails | grep -v pwa | grep -v turbo_stream
```

Expected: 출력 없음 (모든 대상 파일 삭제 완료)

- [ ] **Step 3: 개발 서버로 수동 확인 (선택적)**

```bash
bin/dev
```

- 루트 페이지 (`/`) — nav, footer, flash 확인
- `/about` — About 페이지 렌더링 확인
- `/passwords/new` — 비밀번호 재설정 폼 확인
- `/articles/<id>` — 아티클 상세 페이지 확인

- [ ] **Step 4: 최종 커밋 (필요시)**

```bash
git commit -m "chore: complete ERB to Phlex view migration"
```
