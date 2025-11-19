# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository. 아래 지침은 최신 상태를 유지하며, 불명확한 경우 담당 Maintainer에게 확인하십시오.

- 모든 응답은 한국어로 작성해 주세요. 로그나 명령어 출력은 원문을 유지합니다.
- 변경 전후 맥락과 테스트 결과를 커밋 메시지 또는 PR 설명에 기록해야 합니다.

## Technology Stack

**Ruby-News** is a Korean Ruby-focused news aggregation platform built with Rails 8. Key technologies:

- **Rails 8** with Solid Queue, Solid Cache, Solid Cable for 백그라운드 작업과 실시간 업데이트
- **Ruby 4.0** with RBS inline type annotations; Steep를 통해 서비스/모델 시그니처를 검증합니다.
- **PostgreSQL** with vector embeddings, Korean/English full-text search, `pgvector` 확장을 필수로 사용합니다.
- **AI Integration**: RubyLLM with Gemini models for content processing, 배포 환경에서는 API 키를 `config/credentials.yml.enc`에 보관합니다.
- **Frontend**: Hotwire (Turbo/Stimulus), Tailwind CSS 4.2; 공통 CSS 토큰은 `app/assets/stylesheets/tokens.css`에 정의합니다.

## Development Commands

### Environment Setup
개발 환경 설정 전에 PostgreSQL 확장 설치가 필수입니다:
- **macOS**: [docs/postgresql-extensions.md](docs/postgresql-extensions.md) 참고
- 필수 확장: `pg_bigm`, `textsearch_ko`, `pgvector`
- 마이그레이션 실패 시 확장 설치 상태를 먼저 확인하세요.

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

## Core Architecture

### Domain Models
- **Article**: Central content model with AI-generated summaries, embeddings for similarity; soft-delete(`discarded_at`)이 활성화되어 있습니다. 소셜 미디어 포스트 ID를 `social_post_ids` JSONB 컬럼에 저장하며, `store_accessor`를 통해 `:twitter_id`, `:mastodon_id`로 접근합니다.
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
- `SocialPostJob`: X.com(Twitter)과 Mastodon에 확인된 기사를 자동 게시 (production 환경만)
- `SocialDeleteJob`: Article이 soft-delete될 때 소셜 미디어에서 게시물 삭제
- 모든 Job은 Honeybadger 보고를 위해 `rescue_with_honeybadger`를 호출하고, 재시도 정책은 각 클래스의 `retry_on` 설정을 우선합니다.

### Client Architecture
External service integrations follow consistent pattern:

```ruby
# Basic client pattern (inherits from ApplicationClient)
class RssClient < ApplicationClient
  # Standardized error handling: Forbidden, RateLimit, NotFound
end

# OAuth2-based social media client pattern
class TwitterClient
  def initialize
    oauth_config = Preference.get_object("xcom_oauth")
    # OAuth2 token with automatic refresh capability
  end

  def post(text) # X.com에 트윗 게시
  def delete(tweet_id) # 트윗 삭제
end

class MastodonClient
  def initialize
    oauth_config = Preference.get_object("mastodon_oauth")
    # Bearer token authentication
  end

  def post(text) # Mastodon 상태 게시
  def delete(status_id) # 상태 삭제
end
```

### Search System
Multi-layered search with Korean/English support:

```ruby
# Full-text search (한국어 사전 + tsvector index)
Article.full_text_search_for(term) # index: index_articles_on_tsv

# Language-specific search
Article.title_matching(query)  # Korean dictionary (requires textsearch_ko extension)
Article.body_matching(query)   # English dictionary

# Vector similarity for related articles
article.nearest_neighbors(:embedding, distance: "cosine")
```
- 임베딩 컬럼은 1536차원 `vector` 타입이며, 신규 필드는 `lib/tasks/embeddings.rake`를 참고해 백필하세요.
- **중요**: 한국어 검색은 `textsearch_ko` 확장에 의존하며, `mecab-ko` 형태소 분석기를 사용합니다.
- macOS 환경에서 `textsearch_ko` 설치 시 소스 패치가 필요합니다 ([상세 가이드](docs/postgresql-extensions.md#3-textsearch_ko-소스-빌드-및-패치)).

### Social Media Integration
외부 소셜 미디어 플랫폼에 Article을 자동으로 게시하고 삭제하는 기능:

**지원 플랫폼:**
- **X.com (Twitter)**: 280자 제한, URL은 23자로 계산
- **Mastodon**: 500자 제한 (ruby.social 인스턴스), URL은 실제 길이로 계산

**아키텍처 패턴:**
상속 기반 서비스 패턴으로 플랫폼별 차이를 추상화:

```ruby
# 기본 클래스: 공통 로직 구현
class SocialMediaService < ApplicationService
  def initialize(article, command: :post)  # :post 또는 :delete
end

# 플랫폼별 구현
class TwitterService < SocialMediaService
  def post_to_platform(article)
    # X.com API 연동, 280자 제한 처리
  end

  def delete_from_platform(article)
    # 트윗 삭제 및 twitter_id 초기화
  end
end
```

**OAuth 설정:**
- Twitter: `Preference.get_object("xcom_oauth")`를 통해 OAuth 설정 로드
- Mastodon: `Preference.get_object("mastodon_oauth")`를 통해 OAuth 설정 로드
- Client는 자동으로 토큰 만료 확인 및 갱신 수행 (Twitter만 해당)

**Post ID 추적:**
Article 모델은 게시된 포스트의 ID를 추적하여 삭제 시 사용:
```ruby
article.twitter_id   # X.com 포스트 ID (store_accessor)
article.mastodon_id  # Mastodon 포스트 ID (store_accessor)
```

**Lifecycle:**
1. **게시**: `SocialPostJob`이 `is_posted: false`인 Article을 찾아 게시
2. **삭제**: Article이 soft-delete되면 `after_discard` 콜백이 `SocialDeleteJob`을 예약
3. **Production Only**: 모든 소셜 미디어 작업은 production 환경에서만 실행됨

**에러 핸들링:**
- 각 플랫폼별 실패는 독립적으로 처리 (한 플랫폼 실패가 다른 플랫폼에 영향 없음)
- 모든 오류는 Honeybadger에 보고되며, article_id와 article_url을 컨텍스트로 포함
- 포스트 ID가 없을 경우 삭제 작업은 조용히 스킵됨

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
