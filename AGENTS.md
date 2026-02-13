# AGENTS.md

AI 에이전트를 위한 프로젝트 가이드라인입니다.

- 모든 응답은 **한국어**로 작성. 로그/명령어 출력은 원문 유지.
- 변경 전후 맥락과 테스트 결과를 커밋 메시지 또는 PR 설명에 기록.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│  bin/dev                    개발 서버 (Rails + CSS watcher)     │
│  bin/rails test             테스트 실행                         │
│  bin/rubocop                린트 검사                           │
│  bundle exec steep check    타입 검사                           │
│  bin/brakeman               보안 스캔                           │
│  bin/jobs                   백그라운드 워커                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| 영역 | 기술 |
|------|------|
| **Backend** | Rails 8, Ruby 4.0, Solid Queue/Cache/Cable |
| **Database** | PostgreSQL + pgvector + textsearch_ko + pg_bigm |
| **AI** | RubyLLM + Gemini (한국어 요약/임베딩) |
| **Frontend** | Hotwire (Turbo/Stimulus), Tailwind CSS 4.2 |
| **Type System** | RBS inline + Steep |

### PostgreSQL 확장 (필수)

개발 전 설치 필요: `pg_bigm`, `textsearch_ko`, `pgvector`
- macOS 설치 가이드: [docs/postgresql-extensions.md](docs/postgresql-extensions.md)
- 마이그레이션 실패 시 확장 설치 상태부터 확인

---

## Core Models

| 모델 | 역할 | 주요 특징 |
|------|------|----------|
| **Article** | 콘텐츠 | AI 요약, embedding, soft-delete(`discarded_at`), `social_post_ids` JSONB |
| **Site** | 소스 | `kind` enum (RSS/YouTube/Gmail/HN) |
| **User** | 인증 | Custom auth (not Devise), `Current.user` 패턴 |
| **Comment** | 댓글 | awesome_nested_set, `MAX_DEPTH` 제한 |

---

## Background Jobs

Solid Queue 기반 비동기 처리:

| Job | 역할 |
|-----|------|
| `ArticleJob` | AI 요약/임베딩 생성 |
| `RssSiteJob` | RSS 피드 크롤링 |
| `YoutubeSiteJob` | YouTube 자막 추출 |
| `GmailArticleJob` | 이메일 뉴스레터 처리 |
| `SocialPostJob` | X.com/Mastodon 자동 게시 (production only) |
| `SocialDeleteJob` | soft-delete 시 소셜 포스트 삭제 |

모든 Job은 `rescue_with_honeybadger` 호출, 재시도 정책은 각 클래스의 `retry_on` 설정 우선.

---

## Code Conventions

### Type Annotations (RBS Inline)

```ruby
# rbs_inline: enabled

def process_content(url) #: (String) -> void
```

### Soft Delete

```ruby
include Discard::Model
Article.kept.find_by_slug(params[:id])  # kept scope 사용
```

### Service Layer Pattern

**두 가지 패턴을 혼용:**

| 패턴 | 용도 | 예시 |
|------|------|------|
| `ApplicationService` | 단순 비즈니스 로직 | `SitemapService` |
| `Dry::Operation` | 다단계 워크플로우, 명시적 에러 처리 | `SocialMediaService`, `ContentService` |

**Dry::Operation 사용 시:**
```ruby
class ContentService < Dry::Operation
  def call(article)
    step validate(article)
    step process(article)
  end
end

# 호출
result = ContentService.new.call(article)
result.success? ? result.value! : result.failure
```

### Error Handling

- ApplicationJob: `StandardError` rescue + Honeybadger 보고
- Client 클래스: 표준화된 에러 타입 (`Forbidden`, `RateLimit`, `NotFound`)
- 컨트롤러: `render turbo_stream:` 또는 명시적 status 코드

---

## Search System

```ruby
# 전문 검색 (한국어 사전 + tsvector)
Article.full_text_search_for(term)

# 언어별 검색
Article.title_matching(query)  # Korean dictionary
Article.body_matching(query)   # English dictionary

# 벡터 유사도
article.nearest_neighbors(:embedding, distance: "cosine")
```

- 임베딩: 1536차원 vector 타입
- 한국어 검색: `textsearch_ko` 확장 + `mecab-ko` 형태소 분석기

---

## Social Media Integration

**지원 플랫폼:**
- X.com (Twitter): 280자 제한, URL은 23자로 계산
- Mastodon: 500자 제한 (ruby.social)

**아키텍처:** `Dry::Operation` + 상속 기반 서비스 패턴
- 기본 클래스: `SocialMediaService`
- 플랫폼별: `TwitterService`, `MastodonService`

**OAuth 설정:** `Preference.get_object("xcom_oauth")`, `Preference.get_object("mastodon_oauth")`

**Post ID 추적:** `article.twitter_id`, `article.mastodon_id` (store_accessor)

---

## Testing

테스트 환경은 **PostgreSQL** 사용 (SQLite 아님):
- 이유: pgvector, textsearch_ko, pg_bigm 등 production과 동일한 확장 필요
- 설정: `TEST_DATABASE_URL` 환경 변수 우선

```bash
bin/rails test                                  # 전체 테스트
bin/rails test test/models/article_test.rb      # 단일 파일
bin/rails test:system BROWSER=headless_firefox  # 시스템 테스트
```

---

## CI/CD

GitHub Actions 파이프라인:

| Job | 역할 |
|-----|------|
| `scan_ruby` | Brakeman + bundler-audit |
| `scan_js` | importmap audit |
| `lint` | RuboCop |
| `test` | 전체 테스트 (PostgreSQL) |

**CI PostgreSQL:** 커스텀 이미지 `ghcr.io/stadia/ra-pg17:latest` (모든 확장 사전 설치)

---

## Korean Localization

- Default locale: `:ko`, timezone: `Asia/Seoul`
- AI 요약: 한국어 생성
- 신규 번역 키: `config/locales/ko.yml`
- 날짜/시간: `l(Time.current, format: :short)`

---

## Related Documentation

| 문서 | 설명 |
|------|------|
| [개발 워크플로우](docs/CLAUDE_WORKFLOW.md) | Claude Code 작업 패턴, PR 워크플로우, 커밋 전략 |
| [PostgreSQL 확장](docs/postgresql-extensions.md) | macOS/Linux 설치 가이드 |
| [RubyLLM Agents](app/agents/AGENTS.md) | Agent DSL 레퍼런스 |
| [RubyLLM Tools](app/tools/TOOLS.md) | Tool 생성 가이드 |
| [RubyLLM Workflows](app/workflows/WORKFLOWS.md) | 워크플로우 오케스트레이션 |
