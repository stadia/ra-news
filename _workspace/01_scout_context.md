# Scout Context: Discord Notification + Slack STI Migration

작업 유형: Feature  
날짜: 2026-04-13  
브랜치: claude/discord

---

## 작업 목표

1. Discord webhook 알림 기능 추가 (`discordrb-webhooks` gem)
2. Slack 코드를 통합 STI 모델로 마이그레이션
   - `notification_channels` (SlackWorkspace 대체, STI)
   - `notification_deliveries` (SlackArticleDelivery 대체, STI)

---

## 현재 Slack 구현 현황

### 1. 모델

#### `SlackWorkspace` → `app/models/slack_workspace.rb`

**테이블:** `slack_workspaces`  
**컬럼 목록:**
| 컬럼 | 타입 | NOT NULL | 기본값 |
|------|------|----------|--------|
| team_id | string | YES | |
| team_name | string | YES | |
| bot_access_token | string | YES | |
| bot_user_id | string | YES | |
| status | string | YES | "active" |
| last_verified_at | datetime | no | |
| created_at | datetime | YES | |
| updated_at | datetime | YES | |
| incoming_webhook_url | string | no | |
| channel_id | string | no | |
| channel_name | string | no | |

**인덱스:** `team_id` (unique)

**Associations:** `has_many :slack_article_deliveries, dependent: :destroy`  
**Validations:** `inclusion(status: ["active","inactive","error"])`, `presence(team_id, team_name, incoming_webhook_url, channel_id, channel_name)`, `uniqueness(team_id)`  
**Enum:** `status: active/inactive/error` (string)  
**Scopes:** `active`, `delivery_ready` (active + webhook_url/channel_id/channel_name 존재)

#### `SlackArticleDelivery` → `app/models/slack_article_delivery.rb`

**테이블:** `slack_article_deliveries`  
**컬럼 목록:**
| 컬럼 | 타입 | NOT NULL | 기본값 |
|------|------|----------|--------|
| article_id | bigint | YES | |
| slack_workspace_id | bigint | YES | |
| channel_id | string | YES | |
| channel_name | string | YES | |
| status | string | YES | "failed" |
| sent_at | datetime | no | |
| error_message | text | no | |
| slack_message_ts | string | no | |
| created_at | datetime | YES | |
| updated_at | datetime | YES | |

**Associations:** `belongs_to :article`, `belongs_to :slack_workspace`  
**Validations:** `inclusion(status: ["sent","failed"])`, `presence(channel_id, channel_name)`, `uniqueness(article_id, scope: [:slack_workspace_id, :channel_id])`  
**Enum:** `status: sent/failed` (string)

---

### 2. 클라이언트

#### `SlackClient` → `app/clients/slack_client.rb`

**메서드 시그니처 (rbs_inline 어노테이션 포함):**

```ruby
# 인스턴스 메서드
def initialize(workspace)            # (SlackWorkspace workspace) -> void
def list_channels                    # () -> Array[Hash[String, String]]
def post_message(text:, blocks:)     # (text: String, blocks: Array[untyped]) -> Hash[String, String]

# 클래스 메서드
def self.authorize_url(redirect_uri:, state:)  # (redirect_uri: String, state: String) -> String
def self.exchange_code(code, redirect_uri:)    # (String code, redirect_uri: String) -> ActiveSupport::HashWithIndifferentAccess
def self.oauth_client(token = nil)             # (?String? token) -> Slack::Web::Client
```

**내부 구현:**
- `post_message`: Faraday로 `workspace.incoming_webhook_url`에 POST
- `list_channels`: `Slack::Web::Client#conversations_list`
- 예외: `SlackClient::ApiError < StandardError`
- Gem: `slack-ruby-client ~> 3.1.0`

---

### 3. 서비스

#### `SlackArticleNotifierService` → `app/services/slack_article_notifier_service.rb`

`OperationService` 상속, ROP 패턴  
**`call(article)` 로직:**
1. `article.deleted_at.nil?` 확인 → `Failure(:deleted)`
2. `article.slug.present? && article.title_ko.present?` 확인 → `Failure(:not_confirmed)`
3. `SlackWorkspace.delivery_ready.order(:id)` 로 모든 workspace 조회
4. `SlackArticleDeliveryJob` 인스턴스 배열 생성 후 `ActiveJob.perform_all_later` 일괄 enqueue

---

### 4. Job

#### `SlackArticleDeliveryJob` → `app/jobs/slack_article_delivery_job.rb`

`ApplicationJob`, queue: `:default`  
**`perform(article_id, workspace_id)` 로직:**
1. `Article.find_by`, `SlackWorkspace.find_by` — nil이면 early return
2. `find_or_create_delivery(article, workspace)` — `SlackArticleDelivery` 생성/조회
3. `SlackArticlePresenter.new(article)` → `message.text`, `message.blocks`
4. `delivery.with_lock` 내에서 중복 전송 방지 (`delivery.sent?` 체크)
5. `SlackClient.new(workspace).post_message(text:, blocks:)`
6. 성공: `persist_delivery_success(delivery, channel_name, ts)` — status: sent, sent_at, slack_message_ts 업데이트
7. 실패 `SlackClient::ApiError`: delivery.reload 후 sent? 아닐 때만 `status: failed, error_message` 업데이트

**중복 방지:** `RecordNotUnique` rescue로 `find_by!` 폴백

---

### 5. 프레젠터

#### `SlackArticlePresenter` → `app/presenters/slack_article_presenter.rb`

```ruby
def initialize(article)
def text    # "escaped_title - escaped_summary - escaped_article_url"
def blocks  # Slack Block Kit: section(mrkdwn) + context(article_url 링크, published_label)
```

데이터 소스:
- `article.title_ko.presence || article.title`
- `article.summary_key` (Array면 first, otherwise 그대로) → fallback: `article.base_content[:summary]`
- `article_url(article)` via `routes.url_helpers`
- `I18n.l(article.published_at || Time.current, format: :short)`

---

### 6. 컨트롤러

#### `SlackController` → `app/controllers/slack_controller.rb`

`ApplicationController` 상속  
**라우트:**
- `GET /slack/install` → `install`
- `GET /slack/oauth/callback` → `callback`
- `POST /slack/events` → `events`

**필터:**
- `protect_from_forgery except: :events`
- `skip_before_action :authenticate_user!, only: :events`
- `before_action :verify_slack_signature, only: :events`

**주요 의존:**
- `SlackConfig` (클래스): `configured?`, `client_id`, `client_secret`, `install_scope`, `signing_secret`
- `SlackClient.authorize_url`, `SlackClient.exchange_code`
- HMAC SHA256 서명 검증 (X-Slack-Request-Timestamp, X-Slack-Signature)
- OAuth state: `session[:slack_oauth_state]`

---

### 7. `SocialPostJob` 내 Slack 호출점

`app/jobs/social_post_job.rb` line ~30:
```ruby
SlackArticleNotifierService.new.call(article)
```
`TwitterService`, `MastodonService`와 동일 레벨에서 호출됨. STI 마이그레이션 후 이 호출점도 변경 필요.

---

### 8. Article 모델 연관

`has_many :slack_article_deliveries, dependent: :destroy`  
STI 마이그레이션 후 `has_many :notification_deliveries, dependent: :destroy`로 교체 필요

---

## 테스트 파일 현황 (모두 존재)

| 파일 | 존재 |
|------|------|
| `test/fixtures/slack_workspaces.yml` | YES |
| `test/fixtures/slack_article_deliveries.yml` | YES |
| `test/controllers/slack_controller_test.rb` | YES |
| `test/services/slack_client_test.rb` | YES |
| `test/services/slack_article_notifier_service_test.rb` | YES |
| `test/jobs/slack_article_delivery_job_test.rb` | YES |

**Fixture 주요 데이터:**
- `slack_workspaces`: `acme` (active), `globex` (active) — 2개
- `slack_article_deliveries`: `existing_delivery` (status: sent, article: ruby_article, workspace: acme)

**테스트 패턴:**
- Minitest + fixtures (factories 없음)
- `SlackClient.stub(:new, ...)` — stub 패턴으로 HTTP 호출 격리
- `assert_enqueued_jobs N, only: JobClass` 패턴

---

## Gem 현황

| Gem | 설치 여부 |
|-----|----------|
| `slack-ruby-client ~> 3.1.0` | YES |
| `discordrb-webhooks` | **미설치** |

---

## STI 마이그레이션 설계를 위한 핵심 정보

### 현재 구조 → STI 구조 매핑

**notification_channels (STI):**
- Slack 타입: `team_id`, `team_name`, `bot_access_token`, `bot_user_id`, `incoming_webhook_url`, `channel_id`, `channel_name`, `status`, `last_verified_at`
- Discord 타입: `webhook_url`, `channel_name`, `status` (최소 필요)
- 공통: `type` (STI 컬럼), `status`, `created_at`, `updated_at`

**notification_deliveries (STI):**
- Slack 타입: `slack_message_ts` (Slack 전용)
- 공통: `article_id`, `notification_channel_id`, `channel_id`, `channel_name`, `status`, `sent_at`, `error_message`, `type`

### 영향 받는 파일 목록 (STI 전환 시)

1. `app/models/slack_workspace.rb` → `app/models/notification_channels/slack.rb`
2. `app/models/slack_article_delivery.rb` → `app/models/notification_deliveries/slack.rb`
3. `app/clients/slack_client.rb` — 유지
4. `app/services/slack_article_notifier_service.rb` → 일반화
5. `app/jobs/slack_article_delivery_job.rb` → 일반화
6. `app/presenters/slack_article_presenter.rb` — 유지 or 일반화
7. `app/controllers/slack_controller.rb` — 내부 모델 참조 변경
8. `app/jobs/social_post_job.rb` — 서비스 호출 방식 변경 가능
9. `app/models/article.rb` — associations 변경
10. `db/schema.rb` — 마이그레이션 필요
11. 테스트 파일 6개 전체

---

## 프로젝트 제약 사항

- **Phlex 기반 뷰** (ERB 금지), `Views::Base` 상속
- **컴포넌트:** `Components::Base` 상속, RubyUI 우선
- **서비스:** `OperationService` 상속, ROP 패턴 (`dry-monads`)
- **i18n:** 기본 locale 한국어, `config/locales/ko.yml`
- **Tailwind v4** 시맨틱 토큰 (v3 클래스 금지)
- **인증:** Devise (`current_user`), `authenticate_user!` global before_action
- **DB:** PostgreSQL 전용
- **Job:** `solid_queue`, `ApplicationJob` 상속
- **RBS:** `# rbs_inline: enabled` 어노테이션 패턴 사용 중
- **테스트:** Minitest + fixtures (Faker 사용), stub 패턴으로 외부 HTTP 격리
