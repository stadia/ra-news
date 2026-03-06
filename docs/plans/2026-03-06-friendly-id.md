# friendly_id 도입 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** friendly_id 젬을 도입하여 Article 슬러그를 영어 title 기반으로 자동 생성하고, YouTube ID 슬러그를 설명적 슬러그로 교체하며 301 리다이렉트를 지원한다.

**Architecture:** 기존 `slug` 컬럼을 그대로 사용하되 friendly_id가 관리하도록 전환. `should_generate_new_friendly_id?`를 오버라이드하여 기존 비-YouTube 슬러그는 유지하고 YouTube ID 슬러그와 nil slug만 재생성. `friendly_id_slugs` 테이블이 구 슬러그 history를 보관해 301 리다이렉트를 지원한다.

**Tech Stack:** Rails 8, friendly_id gem (~> 5.5), PostgreSQL, Minitest

---

### Task 1: friendly_id 젬 추가 및 마이그레이션 생성

**Files:**
- Modify: `Gemfile`
- Create: `db/migrate/TIMESTAMP_create_friendly_id_slugs.rb` (rails generate로 생성)

**Step 1: Gemfile에 추가**

```ruby
gem "friendly_id", "~> 5.5"
```

**Step 2: bundle install**

```bash
eval "$(rbenv init -)" && bundle install
```

Expected: friendly_id 설치 완료

**Step 3: friendly_id 마이그레이션 생성**

```bash
eval "$(rbenv init -)" && bundle exec rails generate friendly_id
```

Expected: `db/migrate/TIMESTAMP_create_friendly_id_slugs.rb` 생성

**Step 4: 마이그레이션 실행**

```bash
eval "$(rbenv init -)" && bundle exec rails db:migrate
```

Expected: `friendly_id_slugs` 테이블 생성 완료

**Step 5: 커밋**

```bash
git add Gemfile Gemfile.lock db/migrate db/schema.rb
git commit -m "feat: add friendly_id gem and create friendly_id_slugs table"
```

---

### Task 2: Article 모델에 friendly_id 설정

**Files:**
- Modify: `app/models/article.rb`

**Step 1: 기존 slug 관련 테스트 확인**

```bash
eval "$(rbenv init -)" && bundle exec rails test test/models/article_test.rb 2>&1 | tail -20
```

**Step 2: friendly_id 설정 추가**

`class Article < ApplicationRecord` 바로 다음 블록에 추가:

```ruby
extend FriendlyId
friendly_id :slug_candidates, use: [:slugged, :history]
```

`random_slug` 메서드 위에 다음 인스턴스 메서드 추가 (private 섹션):

```ruby
def slug_candidates
  [title, -> { random_slug }]
end

# 슬러그 재생성 조건:
# - slug가 nil (신규 기사, 아직 슬러그 없음)
# - YouTube 기사인데 slug이 YouTube ID 형식 (11자 alphanumeric+_-)
#   → title 설정 후 설명적 슬러그로 교체
def should_generate_new_friendly_id?
  slug.nil? || (is_youtube? && slug.match?(/\A[A-Za-z0-9_-]{11}\z/))
end
```

**Step 3: `set_youtube_metadata`에서 수동 slug 설정 제거**

`app/models/article.rb` 의 `set_youtube_metadata` 메서드에서 아래 줄을 제거:

```ruby
self.slug = youtube_id   # ← 이 줄 제거
```

제거 후 메서드:
```ruby
def set_youtube_metadata #: void
  video = Yt::Video.new id: youtube_id
  self.published_at = video.published_at if video&.published_at.is_a?(Time)
  self.title = video.title if video&.title.is_a?(String)
rescue Yt::Error => e
  logger.error "YouTube API error for video ID #{youtube_id}: #{e.message}"
end
```

**Step 4: `update_slug` 메서드 수정**

YouTube 기사의 경우 slug를 nil로 초기화하여 friendly_id가 title로 재생성하도록:

```ruby
def update_slug #: bool
  if is_youtube?
    # slug를 nil로 초기화 → should_generate_new_friendly_id? = true → title로 재생성
    update_column(:slug, nil)
    reload
    save
  else
    path = URI.parse(url).path
    new_slug = path&.split("/")&.last&.split(".")&.first
    new_slug = random_slug if new_slug.blank?
    update(slug: new_slug)
  end
rescue URI::InvalidURIError
  logger.error "Invalid URI for slug update: #{url}"
  false
end
```

**Step 5: 기존 find_by_slug 클래스 메서드 제거**

아래 메서드를 제거 (friendly_id가 대체):
```ruby
def self.find_by_slug(slug)
  find_by(slug: slug)
end
```

**Step 6: 테스트 실행**

```bash
eval "$(rbenv init -)" && bundle exec rails test test/models/article_test.rb 2>&1 | tail -30
```

Expected: 기존 테스트 통과 (find_by_slug 관련 테스트는 실패할 수 있음 → Task 3에서 수정)

**Step 7: 커밋**

```bash
git add app/models/article.rb
git commit -m "feat: add friendly_id to Article model with YouTube ID slug detection"
```

---

### Task 3: ArticlesController 업데이트

**Files:**
- Modify: `app/controllers/articles_controller.rb`

**Step 1: set_article 메서드 교체**

현재:
```ruby
def set_article
  id = params[:id]
  return head :bad_request if id.blank?

  @article = Article.kept.find_by_slug(id) || Article.kept.find_by(id: id)
  raise ActiveRecord::RecordNotFound if @article.nil?
end
```

교체:
```ruby
def set_article
  id = params[:id]
  return head :bad_request if id.blank?

  @article = Article.kept.friendly.find(id)
  # 구 슬러그(YouTube ID 등)로 접근 시 현재 slug URL로 301 리다이렉트
  if @article.friendly_id != id
    redirect_to article_path(@article), status: :moved_permanently
  end
rescue ActiveRecord::RecordNotFound
  raise
end
```

**Step 2: article_url/article_path 인자 수정**

`show` 액션의 스키마 블록에서:
```ruby
# Before:
url: article_url(@article.slug),
# After:
url: article_url(@article),
```

`create` 액션에서:
```ruby
# Before:
format.html { redirect_to article_path(existing_article&.slug), notice: "..." }
# After (2곳 모두):
format.html { redirect_to article_path(existing_article), notice: "..." }
```

**Step 3: 컨트롤러 테스트 실행**

```bash
eval "$(rbenv init -)" && bundle exec rails test test/controllers/articles_controller_test.rb 2>&1 | tail -30
```

**Step 4: 커밋**

```bash
git add app/controllers/articles_controller.rb
git commit -m "feat: use friendly_id finder and friendly article_path in ArticlesController"
```

---

### Task 4: 컴포넌트 및 뷰 업데이트

**Files:**
- Modify: `app/components/home/article.rb:31`
- Modify: `app/components/articles/article.rb:31`
- Modify: `app/components/recent_comments_sidebar.rb:53`
- Modify: `app/views/articles/show.html.erb:186`

**Step 1: 컴포넌트 3곳 수정**

`app/components/home/article.rb:31`:
```ruby
# Before:
link_to(display_title, article_path(article.slug))
# After:
link_to(display_title, article_path(article))
```

`app/components/articles/article.rb:31`:
```ruby
# Before:
link_to display_title, article_path(article.slug)
# After:
link_to display_title, article_path(article)
```

`app/components/recent_comments_sidebar.rb:53`:
```ruby
# Before:
link_to(article_path(comment.article.slug), class: "...") do
# After:
link_to(article_path(comment.article), class: "...") do
```

**Step 2: 뷰 수정**

`app/views/articles/show.html.erb:186`:
```erb
<%# Before: %>
<%= link_to article_path(article.slug), class: "block p-4 lg:p-6" do %>
<%# After: %>
<%= link_to article_path(article), class: "block p-4 lg:p-6" do %>
```

**Step 3: 커밋**

```bash
git add app/components/ app/views/articles/show.html.erb
git commit -m "feat: replace article_path(article.slug) with article_path(article) in views"
```

---

### Task 5: Job 및 Service 업데이트

**Files:**
- Modify: `app/jobs/article_batch_job.rb:33`
- Modify: `app/services/sitemap_service.rb:25`

**Step 1: article_batch_job 수정**

`app/jobs/article_batch_job.rb`:
```ruby
# Before:
Rails.application.routes.url_helpers.article_url(
  article.slug.presence || article.id,
  host: "ruby-news.kr",
  protocol: "https"
)
# After:
Rails.application.routes.url_helpers.article_url(
  article,
  host: "ruby-news.kr",
  protocol: "https"
)
```

**Step 2: sitemap_service 수정**

`app/services/sitemap_service.rb:25`:
```ruby
# Before:
add article_path(article.slug), lastmod: article.published_at || article.updated_at
# After:
add article_path(article), lastmod: article.published_at || article.updated_at
```

**Step 3: 전체 테스트 실행**

```bash
eval "$(rbenv init -)" && bundle exec rails test 2>&1 | tail -30
```

Expected: 전체 테스트 통과

**Step 4: 커밋**

```bash
git add app/jobs/article_batch_job.rb app/services/sitemap_service.rb
git commit -m "feat: update article_url/article_path in jobs and services"
```

---

### Task 6: 검증 및 마무리

**Step 1: 전체 테스트 재확인**

```bash
eval "$(rbenv init -)" && bundle exec rails test 2>&1 | tail -40
```

**Step 2: article_path 수동 grep으로 누락 확인**

```bash
grep -rn "article_path(\|article_url(" app/ --include="*.rb" --include="*.erb" | grep "\.slug"
```

Expected: 결과 없음 (모두 교체됨)

**Step 3: 로컬 서버에서 smoke test**

```bash
eval "$(rbenv init -)" && bundle exec rails server
```

- `/articles` 접속 → 기사 목록 정상
- 기사 클릭 → 상세 페이지 정상
- (YouTube 기사) `/articles/YOUTUBE_ID` 접속 → 301 리다이렉트 동작 확인

**Step 4: 최종 push**

```bash
git push
```

---

## 주의사항

- `Article.kept.friendly.find(id)` 가 동작하지 않을 경우: `Article.friendly.find(id).tap { raise ActiveRecord::RecordNotFound unless _1.kept? }` 로 대체
- `social_media_service.rb`의 `article_link(slug)` 는 slug 문자열을 URL helper에 직접 전달하므로 변경 불필요
- `reply_notification_job.rb`는 이미 `parent_comment.article` 객체를 전달하므로 변경 불필요
