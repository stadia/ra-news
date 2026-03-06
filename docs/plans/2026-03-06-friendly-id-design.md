# friendly_id 도입 설계

Date: 2026-03-06

## 배경

현재 Article 슬러그 시스템의 문제:
- YouTube 기사는 비디오 ID(`po4BcSCogsA`)가 슬러그 → 의미 없는 URL
- 슬러그 생성/관리가 모델 내 수동 코드로 분산됨
- 슬러그 변경 시 구 URL 처리(301 리다이렉트) 기능 없음

## 결정 사항

| 항목 | 결정 |
|------|------|
| 기존 비 YouTube 슬러그 | 유지 (재생성 안 함) |
| history (301 리다이렉트) | 사용 (`friendly_id_slugs` 테이블) |
| slug source | `title` (영어) 우선 |
| title 없을 때 | 기존 `random_slug` 유지 |

## 아키텍처

### 변경 전

```
slug 컬럼 직접 관리
find_by_slug(id) || find_by(id: id)
article_path(article.slug)
```

### 변경 후

```
friendly_id가 slug 컬럼 관리
Article.kept.friendly.find(params[:id])
article_path(article)  # to_param이 slug 반환
```

## 구현 상세

### Article 모델

```ruby
extend FriendlyId
friendly_id :slug_candidates, use: [:slugged, :history]

def slug_candidates
  [title, -> { random_slug }]
end

def should_generate_new_friendly_id?
  # 슬러그 없음 → 생성
  # YouTube ID 슬러그 → title로 재생성
  # 나머지 → 기존 슬러그 유지
  slug.nil? || (is_youtube? && slug == youtube_id)
end
```

### 컨트롤러 (set_article)

```ruby
def set_article
  id = params[:id]
  return head :bad_request if id.blank?
  @article = Article.kept.friendly.find(id)
  # 구 슬러그(YouTube ID 등)로 접근 시 301 리다이렉트
  if @article.friendly_id != id
    redirect_to article_path(@article), status: :moved_permanently and return
  end
rescue ActiveRecord::RecordNotFound
  raise
end
```

### 뷰/헬퍼 변경

- `article_path(article.slug)` → `article_path(article)` 전체 교체
- `article_url(article.slug)` → `article_url(article)` 전체 교체

## 데이터 플로우

```
새 기사 생성 (title=nil)
  → should_generate_new_friendly_id? = true (slug nil)
  → random_slug 사용

ArticleJob 번역 완료 → title 설정 → save
  → should_generate_new_friendly_id?
    - 일반 기사: false (기존 slug 유지)
    - YouTube 기사: true → title로 slug 재생성
      → 구 YouTube ID slug를 friendly_id_slugs history에 보존
      → /articles/po4BcSCogsA → 301 → /articles/rails-8-upgrade-guide

구 URL 접근:
  Article.kept.friendly.find("po4BcSCogsA")
  → 레코드 찾음, friendly_id != params[:id]
  → redirect_to article_path(@article), status: 301
```

## 기존 데이터 처리

- 2,900+ 기존 기사: `should_generate_new_friendly_id? = false` → slug 유지
- YouTube 기사: ArticleJob 재실행 또는 별도 rake task로 slug 재생성
- `friendly_id_slugs` 시드 불필요 — 기존 slug는 현재 slug이므로 history 없이도 정상

## 마이그레이션

1. `bundle add friendly_id`
2. `rails generate friendly_id` → `db/migrate/..._create_friendly_id_slugs.rb`
3. `rails db:migrate`
4. Article 모델 변경
5. ArticlesController 변경
6. 뷰/헬퍼 `article_path` 교체

## 영향 범위

- `app/models/article.rb` — friendly_id 설정, should_generate_new_friendly_id? 추가
- `app/controllers/articles_controller.rb` — set_article 변경
- `app/views/**` — article_path/article_url 인자 변경
- `Gemfile` — friendly_id 추가
- `db/migrate/` — friendly_id_slugs 테이블
