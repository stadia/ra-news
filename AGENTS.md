# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository. 아래 지침은 최신 상태를 유지하며, 불명확한 경우 담당 Maintainer에게 확인하십시오.

- 모든 응답은 한국어로 작성해 주세요. 로그나 명령어 출력은 원문을 유지합니다.
- 변경 전후 맥락과 테스트 결과를 커밋 메시지 또는 PR 설명에 기록해야 합니다.

## Technology Stack

**Ruby-News** is a Korean Ruby-focused news aggregation platform built with Rails 8. Key technologies:

- **Rails 8** with Solid Queue, Solid Cache, Solid Cable for 백그라운드 작업과 실시간 업데이트
- **Ruby 3.4** with RBS inline type annotations; Steep를 통해 서비스/모델 시그니처를 검증합니다.
- **PostgreSQL** with vector embeddings, Korean/English full-text search, `pgvector` 확장을 필수로 사용합니다.
- **AI Integration**: RubyLLM with Gemini models for content processing, 배포 환경에서는 API 키를 `config/credentials.yml.enc`에 보관합니다.
- **Frontend**: Hotwire (Turbo/Stimulus), Tailwind CSS 4.2; 공통 CSS 토큰은 `app/assets/stylesheets/tokens.css`에 정의합니다.

## Development Commands

### Running the Application
```bash
bin/dev                    # Start Rails server + CSS watching (via Procfile.dev)
bin/rails server          # Rails server only
bin/rails tailwindcss:watch  # CSS watching only
bin/rails jobs:clear      # 큐에 남은 작업을 초기화 (개발 전용)
```

### Testing & Quality
```bash
bin/rails test            # Run test suite
bin/rubocop               # Lint with RuboCop
bundle exec steep check   # Type checking with Steep
bin/brakeman              # Security analysis
bin/rails test:system BROWSER=headless_firefox  # System 테스트를 headless 모드로 실행
```

### Background Jobs
```bash
bin/jobs                  # Start Solid Queue worker
bin/rails jobs:work       # Alternative job processing
bin/rails jobs:stats      # 큐 상태 확인 (CI 실행 전 수동 점검)
```

### GitHub Actions
프로젝트는 다음 GitHub Actions를 사용합니다:

- **CI** (`.github/workflows/ci.yml`): 보안 스캔, Lint, 테스트 자동 실행
- **Claude Code** (`.github/workflows/claude-code.yml`): 이슈/PR에서 `@claude` 멘션 시 AI 에이전트 자동 실행
  - PR 코멘트에서 `@claude [작업 내용]` 형태로 호출
  - 이슈 본문 또는 코멘트에서 `@claude [작업 내용]` 형태로 호출
  - CLAUDE.md, AGENTS.md 지침을 자동으로 참조하여 한국어로 응답
  - 필수 설정: Repository Secrets에 `ANTHROPIC_API_KEY` 등록 필요

## Core Architecture

### Domain Models
- **Article**: Central content model with AI-generated summaries, embeddings for similarity; soft-delete(`discarded_at`)이 활성화되어 있습니다.
- **Site**: RSS/external feed sources (YouTube, HackerNews, Gmail) and maintains `kind` enum for 소스 구분.
- **User**: Authentication with custom system (not Devise) and stores session tokens via `UserSession` 서비스.
- **Comment**: Nested comment system using awesome_nested_set with `Comment::MAX_DEPTH` 제한을 준수합니다.

### Job Processing Pipeline
Background jobs handle all AI content processing via Solid Queue:

```ruby
# Core AI processing pattern
ArticleJob.perform_later(article.id)
# Uses RubyLLM with Gemini for Korean content analysis
```

Key jobs:
- `ArticleJob`: Main AI summarization pipeline
- `RssSiteJob`: RSS feed processing
- `YoutubeSiteJob`: YouTube video content extraction
- `GmailArticleJob`: Email newsletter processing
- 모든 Job은 Honeybadger 보고를 위해 `rescue_with_honeybadger`를 호출하고, 재시도 정책은 각 클래스의 `retry_on` 설정을 우선합니다.

### Client Architecture
External service integrations follow consistent pattern:

```ruby
# All clients inherit from ApplicationClient
class RssClient < ApplicationClient
  # Standardized error handling: Forbidden, RateLimit, NotFound
end
```

### Search System
Multi-layered search with Korean/English support:

```ruby
# Full-text search (한국어 사전 + tsvector index)
Article.full_text_search_for(term) # index: index_articles_on_tsv

# Language-specific search
Article.title_matching(query)  # Korean dictionary
Article.body_matching(query)   # English dictionary

# Vector similarity for related articles
article.nearest_neighbors(:embedding, distance: "cosine")
```
- 임베딩 컬럼은 1536차원 `vector` 타입이며, 신규 필드는 `lib/tasks/embeddings.rake`를 참고해 백필하세요.

### Authentication Pattern
Custom authentication system (not Devise):
- Uses `Current.user` for context
- `allow_unauthenticated_access` in controllers
- Session-based with bcrypt
- MFA나 OAuth 확장은 `app/lib/auth/providers`에 구현하고, 기본 로그인 흐름을 변경할 경우 QA 팀과 사전 협의가 필요합니다.

## Code Conventions

### Type Annotations
Enable RBS inline in models/controllers:
```ruby
# rbs_inline: enabled

def process_content(url) #: (String) -> void
```

### Soft Delete Pattern
Using discard gem consistently:
```ruby
include Discard::Model
scope :kept  # Use for active records
Article.kept.find_by_slug(params[:id])
```

### AI Tool Integration
Custom tools for LLM interactions:
```ruby
class ArticleBodyTool < RubyLLM::Tool
  # Structured AI content extraction
end
```
- 신규 Tool 추가 시 `tools.yml`에 등록하고 QA 환경에서 feature flag로 점진적 적용을 수행합니다.

### Error Handling
- Rescue StandardError in ApplicationJob with Honeybadger reporting
- Client classes use standardized error types
- Graceful degradation for external API failures
- 컨트롤러는 사용자 오류에 대해 `render turbo_stream:` 또는 명시적 status 코드를 사용하며, 500 오류는 Honeybadger에 보고합니다.

## Korean Localization
- Default locale: `:ko` with Asia/Seoul timezone
- AI summaries generated in Korean
- PostgreSQL configured for Korean text search
- Database uses Korean dictionary for full-text search
- 신규 번역 키는 `config/locales/ko.yml`에 추가하고, 날짜/시간은 `l(Time.current, format: :short)`로 표준화합니다.

## Key Features
- **Content Aggregation**: RSS, YouTube, Gmail, HackerNews
- **AI Summarization**: Korean-language content processing with Gemini
- **Vector Search**: Article similarity and recommendations
- **Nested Comments**: Full comment system with threading
- **Admin Dashboard**: Madmin integration for content management
- **SEO**: Automated sitemap generation and meta tags
- 신규 기능 배포 전에는 큐, 캐시, 검색 인덱스 영향도를 PR 체크리스트에 명시하고 롤백 전략을 마련하십시오.
