# Google 프로그래밍 검색 보조 탭 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 Ruby-News 기사 검색 화면에 URL 상태를 유지하는 Google Programmable Search 보조 탭을 추가하고, 해당 탭에서만 Google 스크립트를 지연 로드해 기존 검색어를 자동 실행한다.

**Architecture:** `ArticlesController#index`가 `source=google`을 정규화하고 Google 탭에서는 PostgreSQL 기사 검색을 건너뛴다. Phlex 컴포넌트가 링크 기반 탭과 Google 검색 마운트 지점을 렌더링하며, 전용 Stimulus 컨트롤러가 Google Element API를 한 번만 로드하고 `execute(query)`를 호출한다.

**Tech Stack:** Rails 8.1, Ruby 4.0, Phlex, RubyUI/Tailwind v4 시맨틱 토큰, Stimulus, Turbo, Google Programmable Search Element Control API, Minitest, PostgreSQL

---

## 파일 구조

- Modify: `app/controllers/articles_controller.rb`
  - `source` 파라미터를 `:ruby_news` 또는 `:google`로 정규화하고 Google 탭의 DB 쿼리를 생략한다.
- Modify: `app/views/articles/index.rb`
  - 검색 소스를 받아 탭 컴포넌트와 선택된 검색 본문을 조합한다.
- Create: `app/components/articles/search_tabs.rb`
  - 링크 기반 탭, 현재 탭 접근성 상태, 검색어 보존 URL을 담당한다.
- Create: `app/components/articles/google_search.rb`
  - Google CSE 마운트 지점, Stimulus 값, 로딩 실패 안내를 렌더링한다.
- Create: `app/javascript/controllers/google_search_controller.js`
  - 외부 스크립트의 단일 지연 로드, 명시적 element 렌더, 검색어 실행, 실패 처리를 담당한다.
- Modify: `config/locales/ko.yml`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ja.yml`
  - 탭명, 로딩 문구, 오류 문구를 제공한다.
- Modify: `test/controllers/articles_controller_test.rb`
  - URL 계약, 조건부 렌더링, 검색어 보존, Google 탭의 DB 검색 생략을 통합 검증한다.

### Task 1: 검색 소스 URL 계약과 서버 분기

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`
- Modify: `app/controllers/articles_controller.rb:17-29`
- Modify: `app/controllers/articles_controller.rb:158-172`

- [ ] **Step 1: 기본 탭과 Google 탭의 실패하는 통합 테스트 작성**

`ArticlesControllerTest`에 다음 테스트를 추가한다. 기존 `index` 테스트와 동일하게
`sign_in_as(users(:john))`을 사용한다.

```ruby
test "GET index renders Ruby-News search as the default source" do
  sign_in_as(users(:john))

  get articles_path(search: " ruby ")

  assert_response :success
  assert_select "[role='tab'][aria-selected='true']", text: "Ruby-News"
  assert_select "a[href='#{articles_path(search: "ruby", source: "google")}']",
    text: "Google 프로그래밍 검색"
  assert_select "#articlesList"
  assert_select "[data-controller='google-search']", count: 0
end

test "GET index renders Google search and preserves the normalized query" do
  sign_in_as(users(:john))

  get articles_path(search: " ruby ", source: "google")

  assert_response :success
  assert_select "[role='tab'][aria-selected='true']", text: "Google 프로그래밍 검색"
  assert_select "a[href='#{articles_path(search: "ruby")}']", text: "Ruby-News"
  assert_select "[data-controller='google-search']" do |nodes|
    assert_equal "ruby", nodes.first["data-google-search-query-value"]
  end
  assert_select "#articlesList", count: 0
end

test "GET index treats unknown search source as Ruby-News" do
  sign_in_as(users(:john))

  get articles_path(search: "ruby", source: "unknown")

  assert_response :success
  assert_select "[role='tab'][aria-selected='true']", text: "Ruby-News"
  assert_select "#articlesList"
  assert_select "[data-controller='google-search']", count: 0
end
```

- [ ] **Step 2: 테스트를 실행해 RED 확인**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test test/controllers/articles_controller_test.rb
```

Expected: 새 탭 셀렉터와 `google-search` 영역이 아직 없어 FAIL.

- [ ] **Step 3: 컨트롤러에 검색 소스 정규화와 Google 분기 구현**

`index`를 다음 구조로 변경한다.

```ruby
def index
  cacheable_page!

  search = normalized_search_term
  source = normalized_search_source

  if source == :google
    return render Views::Articles::Index.new(search: search, source: source)
  end

  @pagy, @articles = pagy(Articles::Query.index_html(search).order(published_at: :desc))
  render Views::Articles::Index.new(
    pagy: @pagy,
    articles: @articles,
    sidebar_tags: sidebar_tags,
    search: search,
    source: source,
    liked_article_ids: liked_article_ids(@articles)
  )
end
```

기존 `normalized_search_term` 인접 위치에 허용 목록 방식의 메서드를 추가한다.

```ruby
def normalized_search_source
  params[:source] == "google" ? :google : :ruby_news
end
```

- [ ] **Step 4: Rails 정적 검증 실행**

Run:

```bash
bin/rails 'ai:tool[validate]' files=app/controllers/articles_controller.rb level=rails
```

Expected: controller syntax/semantic validation PASS.

- [ ] **Step 5: RED 상태를 유지하고 Task 2로 진행**

이 시점에는 `Views::Articles::Index`가 아직 `source`를 받지 않으므로 통합 테스트가
계속 실패한다. 실패하는 상태를 커밋하지 않고 Task 2의 Phlex 구현까지 이어서 진행한다.

### Task 2: Phlex 링크 탭과 Google 검색 영역

**Files:**
- Create: `app/components/articles/search_tabs.rb`
- Create: `app/components/articles/google_search.rb`
- Modify: `app/views/articles/index.rb`
- Modify: `config/locales/ko.yml`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ja.yml`
- Modify: `test/controllers/articles_controller_test.rb`

- [ ] **Step 1: 조건부 마크업과 접근성 테스트 보강**

Google 탭 테스트에 엔진 ID, 오류 영역, 외부 스크립트의 서버 렌더링 부재를 추가한다.

```ruby
assert_select "[data-google-search-engine-id-value='119e8b7b7b2f64488']"
assert_select "[data-google-search-target='container']"
assert_select "[data-google-search-target='error'][hidden]"
assert_select "script[src^='https://cse.google.com/cse.js']", count: 0
```

기본 탭 테스트에는 두 탭의 접근성 계약을 추가한다.

```ruby
assert_select "[role='tablist'][aria-label='검색 소스']"
assert_select "[role='tab']", count: 2
assert_select "[role='tab'][aria-selected='false']", text: "Google 프로그래밍 검색"
```

- [ ] **Step 2: 테스트를 실행해 RED 확인**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test test/controllers/articles_controller_test.rb
```

Expected: 새 Phlex 컴포넌트가 없어 FAIL.

- [ ] **Step 3: 검색 탭 Phlex 컴포넌트 생성**

`app/components/articles/search_tabs.rb`를 생성한다.

```ruby
# frozen_string_literal: true

module Components::Articles
  class SearchTabs < Components::Base
    def initialize(search:, source:)
      @search = search
      @source = source
    end

    def view_template
      nav(
        aria: { label: t("articles.index.search_source") },
        class: "mb-6 border-b border-border-subtle"
      ) do
        div(role: "tablist", aria: { label: t("articles.index.search_source") }, class: "flex gap-6") do
          tab(
            label: t("articles.index.tabs.ruby_news"),
            href: articles_path(search: @search),
            active: @source == :ruby_news
          )
          tab(
            label: t("articles.index.tabs.google"),
            href: articles_path(search: @search, source: "google"),
            active: @source == :google
          )
        end
      end
    end

    private

    def tab(label:, href:, active:)
      a(
        href: href,
        role: "tab",
        aria: { selected: active, current: active ? "page" : nil },
        class: [
          "border-b-2 px-1 py-3 text-sm font-medium transition-colors",
          active ? "border-brand text-accent-text" : "border-transparent text-content-muted hover:text-content"
        ]
      ) { label }
    end
  end
end
```

`border-brand`와 `text-accent-text`는 기존 화면에서 사용 중인 시맨틱 토큰이다.

- [ ] **Step 4: Google 검색 Phlex 컴포넌트 생성**

`app/components/articles/google_search.rb`를 생성한다.

```ruby
# frozen_string_literal: true

module Components::Articles
  class GoogleSearch < Components::Base
    ENGINE_ID = "119e8b7b7b2f64488"

    def initialize(query:)
      @query = query.to_s
    end

    def view_template
      section(
        data: {
          controller: "google-search",
          google_search_engine_id_value: ENGINE_ID,
          google_search_query_value: @query,
          google_search_error_message_value: t("articles.index.google.error")
        },
        aria: { label: t("articles.index.tabs.google") }
      ) do
        p(
          data: { google_search_target: "loading" },
          class: "text-sm text-content-muted"
        ) { t("articles.index.google.loading") }

        div(data: { google_search_target: "container" })

        p(
          data: { google_search_target: "error" },
          class: "rounded-lg border border-border-subtle bg-surface p-4 text-sm text-content-secondary",
          hidden: true
        )
      end
    end
  end
end
```

- [ ] **Step 5: 기사 인덱스 뷰를 두 검색 본문으로 분기**

initializer 기본값과 `source`를 추가한다.

```ruby
def initialize(
  pagy: nil,
  articles: [],
  sidebar_tags: [],
  search: nil,
  source: :ruby_news,
  liked_article_ids: []
)
  @pagy = pagy
  @articles = articles
  @sidebar_tags = sidebar_tags
  @search = search
  @source = source
  @liked_article_ids = liked_article_ids
end
```

제목 블록 다음에 탭을 렌더링하고, 기존 기사 결과 레이아웃을 private
`render_ruby_news_results`로 이동한다.

```ruby
render Components::Articles::SearchTabs.new(search: @search, source: @source)

if @source == :google
  render Components::Articles::GoogleSearch.new(query: @search)
else
  render_ruby_news_results
end
```

`render_item_list_schema`는 Google 탭에서 빈 배열로 자연스럽게 반환하고,
제목의 건수 문구는 Ruby-News 탭에서만 출력한다.

```ruby
p(class: "text-lg text-content-secondary") do
  if @source == :google
    plain t("articles.index.google.description")
  else
    plain t("articles.index.count", count: @pagy.count)
    plain " #{@search}" if @search.present?
  end
end
```

- [ ] **Step 6: 세 locale에 번역 추가**

각 locale의 `articles.index` 아래에 같은 키 구조를 추가한다.

```yaml
# config/locales/ko.yml
search_source: 검색 소스
tabs:
  ruby_news: Ruby-News
  google: Google 프로그래밍 검색
google:
  description: Google 프로그래밍 검색에서 더 넓게 찾아봅니다.
  loading: Google 검색을 불러오는 중입니다.
  error: Google 검색을 불러오지 못했습니다. 잠시 후 다시 시도하거나 Ruby-News 검색을 이용해 주세요.
```

```yaml
# config/locales/en.yml
search_source: Search source
tabs:
  ruby_news: Ruby-News
  google: Google Programming Search
google:
  description: Search more broadly with Google Programming Search.
  loading: Loading Google Search.
  error: Google Search could not be loaded. Try again later or use Ruby-News search.
```

```yaml
# config/locales/ja.yml
search_source: 検索元
tabs:
  ruby_news: Ruby-News
  google: Google プログラミング検索
google:
  description: Google プログラミング検索でさらに広く検索します。
  loading: Google 検索を読み込んでいます。
  error: Google 検索を読み込めませんでした。しばらくしてから再試行するか、Ruby-News 検索をご利用ください。
```

- [ ] **Step 7: Rails 검증과 통합 테스트 실행**

Run:

```bash
bin/rails 'ai:tool[validate]' \
  files=app/views/articles/index.rb,app/components/articles/search_tabs.rb,app/components/articles/google_search.rb \
  level=rails
```

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test test/controllers/articles_controller_test.rb
```

Expected: validation PASS, controller tests PASS.

- [ ] **Step 8: Phlex UI 변경 커밋**

```bash
git add app/controllers/articles_controller.rb app/views/articles/index.rb \
  app/components/articles/search_tabs.rb \
  app/components/articles/google_search.rb config/locales/ko.yml \
  config/locales/en.yml config/locales/ja.yml test/controllers/articles_controller_test.rb
git commit -m "검색 결과에 Google 보조 검색 탭 추가"
```

### Task 3: Google CSE 지연 로드와 자동 검색

**Files:**
- Create: `app/javascript/controllers/google_search_controller.js`
- Modify: `test/controllers/articles_controller_test.rb`

- [ ] **Step 1: Stimulus 계약을 통합 테스트에 고정**

Google 탭 테스트에 필요한 Stimulus values와 targets를 고정한다.

```ruby
assert_select "[data-controller='google-search']" do
  assert_select "[data-google-search-engine-id-value='119e8b7b7b2f64488']"
  assert_select "[data-google-search-query-value='ruby']"
  assert_select "[data-google-search-error-message-value]"
  assert_select "[data-google-search-target='loading']"
  assert_select "[data-google-search-target='container']"
  assert_select "[data-google-search-target='error'][hidden]"
end
```

- [ ] **Step 2: 테스트를 실행해 Stimulus 마크업 계약 확인**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test test/controllers/articles_controller_test.rb
```

Expected: Task 2가 완료되었다면 PASS. 이 테스트는 JS 컨트롤러가 의존할 서버 계약을 고정한다.

- [ ] **Step 3: 전용 Stimulus 컨트롤러 생성**

`app/javascript/controllers/google_search_controller.js`를 생성한다.

```javascript
import { Controller } from "@hotwired/stimulus"

const SCRIPT_ID = "google-programmable-search-script"
const LOAD_TIMEOUT_MS = 10_000
const ELEMENT_NAME = "ruby-news-programming-search"

let googleSearchPromise

function loadGoogleSearch(engineId) {
  if (window.google?.search?.cse?.element) return Promise.resolve()
  if (googleSearchPromise) return googleSearchPromise

  googleSearchPromise = new Promise((resolve, reject) => {
    window.__gcse = {
      parsetags: "explicit",
      callback: resolve
    }

    const existingScript = document.getElementById(SCRIPT_ID)
    if (existingScript) {
      existingScript.addEventListener("error", reject, { once: true })
      return
    }

    const script = document.createElement("script")
    script.id = SCRIPT_ID
    script.async = true
    script.src = `https://cse.google.com/cse.js?cx=${encodeURIComponent(engineId)}`
    script.addEventListener("error", reject, { once: true })
    document.head.appendChild(script)
  })

  return googleSearchPromise
}

export default class extends Controller {
  static targets = ["container", "loading", "error"]
  static values = {
    engineId: String,
    query: String,
    errorMessage: String
  }

  connect() {
    this.load()
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
  }

  async load() {
    this.timeoutId = window.setTimeout(() => this.showError(), LOAD_TIMEOUT_MS)

    try {
      await loadGoogleSearch(this.engineIdValue)
      if (!this.element.isConnected) return

      window.google.search.cse.element.render({
        div: this.containerTarget,
        tag: "search",
        gname: ELEMENT_NAME
      })

      if (this.queryValue) {
        window.google.search.cse.element.getElement(ELEMENT_NAME).execute(this.queryValue)
      }

      window.clearTimeout(this.timeoutId)
      this.loadingTarget.hidden = true
    } catch {
      this.showError()
    }
  }

  showError() {
    window.clearTimeout(this.timeoutId)
    this.loadingTarget.hidden = true
    this.errorTarget.textContent = this.errorMessageValue
    this.errorTarget.hidden = false
  }
}
```

구현 중 공식 Element Control API 문서의 현재 시그니처를 다시 확인한다:

- `google.search.cse.element.render(options)`
- `google.search.cse.element.getElement(gname).execute(query)`
- `window.__gcse.parsetags = "explicit"`

Reference: https://developers.google.com/custom-search/docs/element

- [ ] **Step 4: 중복 로드 실패 복구 보강**

스크립트 네트워크 오류 뒤 재방문이 가능하도록 reject 시 singleton을 초기화한다.
`loadGoogleSearch`의 Promise 끝에 다음 처리를 붙인다.

```javascript
googleSearchPromise = googleSearchPromise.catch((error) => {
  googleSearchPromise = undefined
  document.getElementById(SCRIPT_ID)?.remove()
  throw error
})
```

- [ ] **Step 5: JavaScript 및 Rails 마크업 검증**

Run:

```bash
bin/rails 'ai:tool[validate]' \
  files=app/javascript/controllers/google_search_controller.js,app/components/articles/google_search.rb \
  level=rails
```

Expected: JavaScript syntax와 Phlex semantic validation PASS.

- [ ] **Step 6: 지연 로더 변경 커밋**

```bash
git add app/javascript/controllers/google_search_controller.js \
  app/components/articles/google_search.rb test/controllers/articles_controller_test.rb
git commit -m "Google 검색 스크립트 지연 로드 구현"
```

### Task 4: 그래프 갱신, PostgreSQL 검증, 브라우저 확인

**Files:**
- Refresh: `graphify-out/`

- [ ] **Step 1: 코드 변경 후 graphify 지식 그래프 갱신**

Run:

```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Expected: `graphify-out/GRAPH_REPORT.md`와 관련 그래프 산출물이 현재 코드로 갱신됨.

- [ ] **Step 2: 관련 컨트롤러 테스트를 PostgreSQL로 실행**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test test/controllers/articles_controller_test.rb
```

Expected: PASS, failures 0, errors 0.

- [ ] **Step 3: 전체 Rails 테스트로 coverage snapshot 갱신**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rails test
```

Expected: PASS and `coverage/.quality_last_run.json` refreshed.

- [ ] **Step 4: 품질 게이트 실행**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test \
  bin/rake quality
```

Expected:

- Line coverage >= 70.0%
- Branch coverage >= 50.0%
- Flog method max <= 93
- Flog class max <= 289

실패하면 현재 수치와 해당 gate 번호를 기록하고 회귀인지 기존 baseline 문제인지 구분한다.

- [ ] **Step 5: 로컬 서버에서 지연 로드와 URL 상태 브라우저 검증**

Run:

```bash
bin/dev
```

Browser 검증:

1. 로그인 후 `/articles?search=ruby`를 연다.
2. Ruby-News 탭이 선택되고 `#articlesList`가 보이는지 확인한다.
3. 네트워크/DOM에서 `cse.google.com/cse.js`가 아직 없는지 확인한다.
4. `Google 프로그래밍 검색` 탭을 누른다.
5. URL이 `/articles?search=ruby&source=google`인지 확인한다.
6. Google 스크립트가 한 번만 로드되고 검색 입력/결과에 `ruby`가 적용되는지 확인한다.
7. 뒤로 가기, 앞으로 가기, 새로고침 후 선택 탭과 검색어가 유지되는지 확인한다.
8. 모바일 폭에서 두 탭이 잘리지 않고 키보드 포커스가 보이는지 확인한다.

- [ ] **Step 6: 최종 변경과 gate 결과 커밋**

```bash
git add graphify-out app/controllers/articles_controller.rb app/views/articles/index.rb \
  app/components/articles/search_tabs.rb app/components/articles/google_search.rb \
  app/javascript/controllers/google_search_controller.js config/locales/ko.yml \
  config/locales/en.yml config/locales/ja.yml test/controllers/articles_controller_test.rb
git commit -m "Google 프로그래밍 검색 보조 탭 완성"
```
