# Guard Report — Discord Notification 구현

**판정: WARN**

## 1. rails_validate 결과

17/17 파일 구문 검증 통과. 인덱스 경고는 `t.references`가 자동 생성하므로 false positive.

## 2. 테스트 실행 결과

```
373 runs, 1378 assertions, 1 failure, 16 errors, 0 skips
```

- **1 failure + 16 errors 모두 기존 이슈** (본 작업과 무관):
  - PostTest 4건: `private method 'handle_federated_object?'` — 기존 Post 모델 버그
  - LikeFederationServiceTest: Yt::Models::Video 관련 (builder 보고서와 일치)
- Discord/Slack 관련 테스트: 전부 통과

## 3. 컨벤션 확인

| 항목 | 결과 |
|------|------|
| STI 상속 체인 | PASS — `DiscordChannel < NotificationChannel < ApplicationRecord` |
| OperationService 상속 | PASS — `DiscordArticleNotifierService < OperationService` |
| 라우트 | PASS — 4개 라우트 올바르게 추가 (install, callback, channels, setup) |
| i18n | N/A — flash 메시지가 하드코딩 한국어 (기존 SlackController와 동일 패턴) |
| 뷰 | **WARN** — `discord/channels.html.erb`가 ERB로 작성됨. 프로젝트 컨벤션은 Phlex (112 components 전부 Phlex) |
| Stimulus 수동 등록 | PASS — controllers/index.js 미수정 |

## 4. 경계면 정합성

| 경계면 | 결과 |
|--------|------|
| DiscordController → DiscordClient | PASS — authorize_url, exchange_code, list_channels, create_webhook 모두 정합 |
| DiscordController → DiscordChannel | PASS — find_or_initialize_by, assign_attributes 올바름 |
| DiscordArticleDeliveryJob → DiscordDelivery | PASS — find_or_create + update! 패턴 올바름 |
| DiscordArticleNotifierService → DiscordChannel.delivery_ready | PASS — scope은 NotificationChannel에 정의, STI로 상속 |
| SocialPostJob → DiscordArticleNotifierService | PASS — `.new.call(article)` 올바름 |
| Fixture 참조 | PASS — notification_deliveries.yml의 `notification_channel: acme_slack`이 notification_channels.yml의 `acme_slack` 참조 |

## 5. 이전 참조 잔재

### app/ 디렉토리
- `app/services/slack_article_notifier_service.rb:11` — `SlackArticleDeliveryJob` 참조: **정상** (Slack 전용 job 클래스명)
- `app/jobs/slack_article_delivery_job.rb:4` — 클래스 정의: **정상**
- `app/models/AGENTS.md` — 오래된 SlackWorkspace/SlackArticleDelivery 참조: **WARN** (자동생성 문서, 기능 무관)

### test/ 디렉토리
- `test/services/slack_article_notifier_service_test.rb` — `SlackArticleDeliveryJob` 참조: **정상** (Slack 테스트)
- `test/jobs/slack_article_delivery_job_test.rb` — `SlackArticleDeliveryJob` 클래스 참조: **정상**

**SlackWorkspace, SlackArticleDelivery, slack_workspaces, slack_article_deliveries 잔재: app/, test/ 코드에 없음** (AGENTS.md 제외)

## 6. OperationService ROP 패턴 위반

`DiscordArticleNotifierService#call`이 `return nil`과 `return true`를 반환하는 구간이 있음 (line 14, 18). OperationService(Dry::Operation)는 `Success`/`Failure` 모나드를 반환해야 하지만, 기존 `SlackArticleNotifierService`도 동일 패턴이므로 프로젝트 내 허용 관행으로 판단.

## 7. 보안

- OAuth state 검증: `SecureRandom.hex(16)` + `secure_compare` — PASS
- bot_token을 세션에 임시 저장 후 setup 완료 시 삭제 — PASS
- webhook_url이 DB에 평문 저장: 기존 Slack과 동일. 암호화 권장하나 기존 관행 유지.

## 수정 권고 (선택)

1. **`app/views/discord/channels.html.erb`** — Phlex 뷰 클래스로 전환 권장 (프로젝트 컨벤션). 기능에는 영향 없음.
2. **`app/models/AGENTS.md`** — `rails ai:context` 재실행으로 자동 갱신 필요.
