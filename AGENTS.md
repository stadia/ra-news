# AGENTS.md

AI 에이전트를 위한 프로젝트 가이드라인입니다.

- 모든 응답은 **한국어**로 작성. 로그/명령어 출력은 원문 유지.
- 변경 전후 맥락과 테스트 결과를 커밋 메시지 또는 PR 설명에 기록.

---

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

## Code Conventions

### Type Annotations (RBS Inline)

```ruby
# rbs_inline: enabled

def process_content(url) #: (String) -> void
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

## MCP Tools

사용 가능한 MCP 서버와 주요 도구 목록입니다. 작업 유형에 맞는 도구를 선택하세요.

### Serena (코드 시맨틱 분석 & 편집)

코드의 심볼(클래스, 메서드 등)을 의미 기반으로 탐색·편집하는 도구입니다. 파일 전체를 읽는 대신 심볼 단위로 효율적으로 작업합니다.

**프로젝트 활성화:** `activate_project("ruby-news")` 필수 (첫 사용 시)

### Rails MCP Server (Rails 인트로스펙션)

Rails 앱의 모델, 라우트, 스키마 등을 런타임에서 분석합니다. `execute_tool`로 호출합니다.

### Context7 (라이브러리 문서 검색)

최신 라이브러리 문서와 코드 예제를 검색합니다.

**사용 흐름:** `resolve-library-id` → `query-docs` 순서로 호출

### Sequential Thinking (단계적 사고)

복잡한 문제를 단계별로 분석할 때 사용합니다. 가설 생성·검증, 분기, 이전 단계 수정이 가능합니다.

---

## Related Documentation

| 문서 | 설명 |
|------|------|
| [개발 워크플로우](docs/CLAUDE_WORKFLOW.md) | Claude Code 작업 패턴, PR 워크플로우, 커밋 전략 |
| [PostgreSQL 확장](docs/postgresql-extensions.md) | macOS/Linux 설치 가이드 |
