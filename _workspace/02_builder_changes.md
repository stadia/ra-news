# Builder Changes — Task 1~11

## 변경/생성 파일 목록

### Task 1: Gem 추가
- `Gemfile` — `discordrb-webhooks` gem 추가 (v3.7.2 설치됨)

### Task 2: 마이그레이션 — notification 테이블 생성
- `db/migrate/20260413094402_create_notification_tables.rb` — notification_channels, notification_deliveries 테이블 생성

### Task 3: STI 모델 + Fixtures
- `app/models/notification_channel.rb` (신규) — STI 부모 모델
- `app/models/slack_channel.rb` (신규) — SlackChannel STI 자식
- `app/models/discord_channel.rb` (신규) — DiscordChannel STI 자식
- `app/models/notification_delivery.rb` (신규) — STI 부모 모델
- `app/models/slack_delivery.rb` (신규) — SlackDelivery STI 자식
- `app/models/discord_delivery.rb` (신규) — DiscordDelivery STI 자식
- `app/models/article.rb` — `has_many :slack_article_deliveries` → `has_many :notification_deliveries`
- `test/fixtures/notification_channels.yml` (신규) — acme_slack, globex_slack, acme_discord
- `test/fixtures/notification_deliveries.yml` (신규) — existing_slack_delivery

### Task 4: 데이터 마이그레이션
- `db/migrate/20260413094449_migrate_slack_to_notification_tables.rb` — slack_workspaces/slack_article_deliveries 데이터를 새 테이블로 복사 (NULL webhook_url 레코드 제외)

### Task 5: Slack 코드 전환
- `app/clients/slack_client.rb` — workspace→channel, list_channels 제거, webhook_url 참조 변경
- `app/controllers/slack_controller.rb` — SlackWorkspace→SlackChannel, 컬럼명 매핑, bot_access_token/bot_user_id 제거
- `app/jobs/slack_article_delivery_job.rb` — SlackWorkspace→SlackChannel, SlackArticleDelivery→SlackDelivery, slack_message_ts→message_id
- `app/services/slack_article_notifier_service.rb` — SlackWorkspace→SlackChannel, workspace→channel
- `test/services/slack_client_test.rb` — fixture/모델 참조 업데이트
- `test/services/slack_article_notifier_service_test.rb` — fixture/모델 참조 업데이트
- `test/controllers/slack_controller_test.rb` — assertion 업데이트 (bot_access_token/bot_user_id 제거)
- `test/jobs/slack_article_delivery_job_test.rb` — fixture/모델 참조 업데이트

### Task 6: DiscordConfig + DiscordClient
- `app/models/discord_config.rb` (신규) — SlackConfig 패턴 그대로. Preference.get_object("discord_oauth") 기반
- `app/clients/discord_client.rb` (신규) — discordrb-webhooks 기반 embed 전송, OAuth 코드 교환, 채널 목록, 웹훅 생성
- `test/clients/discord_client_test.rb` (신규) — post_embed, authorize_url, ApiError 래핑 테스트

### Task 7: DiscordArticlePresenter
- `app/presenters/discord_article_presenter.rb` (신규) — SlackArticlePresenter 패턴 참고. Discord embed 형식 반환
- `test/presenters/discord_article_presenter_test.rb` (신규) — embed_params 형식, title fallback 테스트

### Task 8: DiscordController + routes + view
- `config/routes.rb` — Discord 라우트 4개 추가 (install, callback, channels, setup)
- `app/controllers/discord_controller.rb` (신규) — SlackController 패턴. OAuth flow + 채널 선택 + 웹훅 생성
- `app/views/discord/channels.rb` (신규) — Phlex 뷰 (Views::Discord::Channels). ERB에서 전환
- `test/controllers/discord_controller_test.rb` (신규) — install, callback, channels, setup 플로우 테스트

### Task 12: Discord channels ERB → Phlex 전환
- `app/views/discord/channels.rb` (수정) — Phlex 뷰 생성 (Views::Base 상속, RubyUI 컴포넌트 사용)
- `app/controllers/discord_controller.rb` (수정) — channels 액션에서 Phlex 뷰 명시적 render
- `app/views/discord/channels.html.erb` (삭제) — Phlex 전환 완료

### Task 13: AGENTS.md 모델 참조 갱신
- `app/models/AGENTS.md` (수정) — SlackWorkspace → SlackChannel, SlackArticleDelivery → SlackDelivery 참조 교체

### Task 9: DiscordArticleNotifierService + DiscordArticleDeliveryJob
- `app/services/discord_article_notifier_service.rb` (신규) — SlackArticleNotifierService 패턴 그대로. DiscordChannel.delivery_ready 기반
- `app/jobs/discord_article_delivery_job.rb` (신규) — SlackArticleDeliveryJob 패턴 그대로. DiscordClient.post_embed 사용
- `test/services/discord_article_notifier_service_test.rb` (신규) — enqueue, confirmed 체크 테스트
- `test/jobs/discord_article_delivery_job_test.rb` (신규) — 전송 실패/성공 핸들링 테스트

### Task 10: SocialPostJob에 Discord 통합
- `app/jobs/social_post_job.rb` — `DiscordArticleNotifierService.new.call(article)` 추가

### Task 11: 이전 테이블 삭제 + 정리
- `db/migrate/20260413102907_drop_slack_tables.rb` (신규) — slack_article_deliveries, slack_workspaces 테이블 삭제
- `app/models/slack_workspace.rb` (삭제)
- `app/models/slack_article_delivery.rb` (삭제)
- `test/fixtures/slack_workspaces.yml` (삭제)
- `test/fixtures/slack_article_deliveries.yml` (삭제)
- `test/models/article_slack_notification_test.rb` (삭제)

## 마이그레이션
- 3개 마이그레이션 생성 및 실행 완료
- `db:migrate` 상태: 성공

## 테스트 결과
- 33 runs, 113 assertions, 0 failures, 0 errors (Discord + Slack 관련 테스트 전체)
- LikeFederationServiceTest 5개 에러는 기존 이슈 (Yt::Models::Video 관련, 본 작업과 무관)

## 참고 사항
- discordrb-webhooks의 `execute` 메서드는 `RestClient::Response`를 반환. `wait: true`로 호출 시 메시지 JSON 응답 수신 가능
- `Discordrb::Errors` 네임스페이스는 discordrb-webhooks gem에 포함되지 않음 (full discordrb에만 존재). `RestClient::Exception` + `StandardError`로 rescue
- Discord OAuth는 guild 정보를 세션에 임시 저장 후 채널 선택 단계에서 사용
