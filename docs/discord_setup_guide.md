# Discord 앱 설정 가이드

이 가이드는 AlNews 프로젝트에서 Discord 알림을 설정하는 전체 과정을 안내합니다.

## 목차

1. [Discord 앱 생성](#1-discord-앱-생성)
2. [Discord 앱 설정](#2-discord-앱-설정)
3. [Rails 프로젝트 설정](#3-rails-프로젝트-설정)
4. [설치 및 인증](#4-설치-및-인증)
5. [채널 설정](#5-채널-설정)
6. [테스트](#6-테스트)

---

## 1. Discord 앱 생성

### 1.1 Discord Developer Portal 접속

1. [Discord Developer Portal](https://discord.com/developers/applications)에 접속
2. Discord 계정으로 로그인

### 1.2 새 앱 생성

1. **New Application** 버튼 클릭
2. 앱 이름 입력 (예: `AlNews`)
3. **Create** 버튼 클릭

---

## 2. Discord 앱 설정

### 2.1 기본 정보 설정

1. **General Information** 탭에서 다음 정보 입력:
   - Name: `AlNews`
   - Description: `AI 뉴스 알림 봇`
   - Icon: 프로젝트 로고 업로드 (선택사항)

### 2.2 OAuth2 설정

1. **OAuth2** → **General** 탭으로 이동
2. **Client ID** 복사 (Rails 환경 변수에 필요)
3. **Client Secret** 생성 및 복사:
   - **Reset Secret** 버튼 클릭
   - 생성된 시크릿 복사 (Rails 환경 변수에 필요)
4. **Redirects**에 다음 URL 추가:
   ```text
   https://your-domain.com/discord/oauth/callback
   ```
   - 로컬 개발 환경:
   ```text
   http://localhost:3000/discord/oauth/callback
   ```

### 2.3 권한 설정 (Scopes)

**OAuth2** → **URL Generator**에서 다음 권한 추가:

| Scope | 설명 |
|-------|------|
| `bot` | 봇 권한 |
| `webhook.incoming` | 웹훅크 생성 권한 |

### 2.4 봇 권한 (Bot Permissions)

**Bot Permissions**에서 다음 권한 체크:

| 권한 | 설명 |
|------|------|
| `Send Messages` | 메시지 전송 |
| `Embed Links` | 임베드 링크 |
| `Manage Webhooks` | 웹훅크 관리 |

### 2.5 봇 생성

1. **Bot** 탭으로 이동
2. **Reset Token** 버튼 클릭
3. 생성된 토큰 복사 (Rails 환경 변수에 필요)
4. **Public Bot** 체크 (사용자가 앱을 검색할 수 있도록)
5. **Require OAuth2 Code Grant** 체크 해제

### 2.6 봇 초대 링크 생성

1. **OAuth2** → **URL Generator** 탭으로 이동
2. **Scopes**에서 `bot` 선택
3. **Bot Permissions**에서 위에서 설정한 권한 자동 추가됨
4. **Generated URL** 복사

---

## 3. Rails 프로젝트 설정

### 3.1 환경 변수 설정

`.env` 파일 또는 `config/credentials.yml.enc`에 다음 변수 추가:

```bash
# Discord OAuth2
DISCORD_CLIENT_ID=your_client_id
DISCORD_CLIENT_SECRET=your_client_secret
DISCORD_BOT_TOKEN=your_bot_token

# 봇 초대 링크 (선택사항)
DISCORD_INVITE_URL=https://discord.com/oauth2/authorize?client_id=...
```

### 3.2 Gemfile 확인

Gemfile에 다음 gem들이 있는지 확인:

```ruby
gem 'discordrb-webhooks', '~> 3.4'  # Discord 웹훅크 클라이언트
```

### 3.3 봇을 서버에 초대

생성한 봇 초대 링크로 이동하여 봇을 테스트 서버에 초대합니다.

---

## 4. 설치 및 인증

### 4.1 설치 페이지 접속

1. 브라우저에서 `/discord/install` 접속
2. 로그인 상태인지 확인

### 4.2 OAuth2 인증

1. 설치 페이지에서 Discord로 이동
2. 앱에 대한 권한 요청
3. **Authorize** 클릭

### 4.3 콜백 처리

OAuth2 콜백이 처리되고:
1. Discord 서버 정보 수집
2. 사용자의 채널 목록 표시
3. 알림을 보낼 채널 선택 가능

---

## 5. 채널 설정

### 5.1 채널 선택

1. `/discord/channels` 페이지 접속
2. 사용 가능한 채널 목록 확인
3. 알림을 보낼 채널 선택

### 5.2 웹훅크 생성

선택한 채널에 웹훅크가 자동으로 생성됩니다:
- 웹훅크 URL 저장
- 채널 정보 (`DiscordChannel` 모델) 저장

### 5.3 채널 검증

웹훅크가 정상적으로 동작하는지 검증:
```ruby
# DiscordChannel 모델
class DiscordChannel < NotificationChannel
  enum status: { active: 'active', inactive: 'inactive', error: 'error' }
end
```

---

## 6. 테스트

### 6.1 단위 테스트

#### DiscordClient 테스트
```bash
rails test test/clients/discord_client_test.rb
```

테스트 항목:
- 웹훅크 전송 성공
- 웹훅크 전송 실패 처리
- 임베드 메시지 형식

#### DiscordArticleNotifierService 테스트
```bash
rails test test/services/discord_article_notifier_service_test.rb
```

테스트 항목:
- 알림 생성
- 임베드 메시지 포맷팅

#### DiscordArticleDeliveryJob 테스트
```bash
rails test test/jobs/discord_article_delivery_job_test.rb
```

테스트 항목:
- 백그라운드 작업 실행
- 에러 처리
- 상태 업데이트

### 6.2 통합 테스트

#### DiscordController 테스트
```bash
rails test test/controllers/discord_controller_test.rb
```

테스트 항목:
- OAuth2 콜백
- 채널 목록 가져오기
- 채널 설정

### 6.3 수동 테스트

#### 1. 봇 설치 테스트
```bash
# 브라우저에서
open http://localhost:3000/discord/install
```

#### 2. 알림 테스트

Rails console에서 테스트:

```ruby
# 테스트 아티클 생성
article = Article.first

# Discord 채널 확인
discord_channel = DiscordChannel.active.first

# 알림 서비스 실행
DiscordArticleNotifierService.new(article, discord_channel).call
```

#### 3. Discord 메시지 확인

Discord 서버의 해당 채널에서 알림 메시지 확인:
- 제목 (아티클 제목)
- 요약 (아티클 요약)
- 링크 (아티클 URL)
- 태그 (아티클 태그)

### 6.4 프레젠테이션 테스트

#### DiscordArticlePresenter 테스트
```bash
rails test test/presenters/discord_article_presenter_test.rb
```

테스트 항목:
- 임베드 제목 생성
- 임베드 설명 생성
- 필드 포맷팅

---

## 7. 문제 해결

### 7.1 OAuth2 인증 실패

**증상**: 콜백 처리 실패, 리다이렉션 오류

**해결**:
1. Redirect URI가 정확한지 확인
2. Client ID와 Client Secret이 올바른지 확인
3. Discord Developer Portal 설정 확인

### 7.2 웹훅크 전송 실패

**증상**: `DiscordChannel` 상태가 `error`

**해결**:
1. 웹훅크 URL이 올바른지 확인
2. 봇이 서버에 있는지 확인
3. 봇에 권한이 있는지 확인 (`Send Messages`, `Manage Webhooks`)

### 7.3 권한 부족

**증상**: 메시지 전송 실패, `403 Forbidden` 에러

**해결**:
1. 봇 권한 확인 (`Manage Webhooks`)
2. 봇이 채널에 있는지 확인
3. 채널 권한 확인

---

## 8. 모니터링

### 8.1 배달 상태 확인

```ruby
# 성공한 배달
DiscordDelivery.sent.count

# 실패한 배달
DiscordDelivery.failed.count

# 특정 아티클 배달 상태
DiscordDelivery.where(article: article)
```

### 8.2 에러 모니터링

```ruby
# 에러가 있는 배달
DiscordDelivery.where.not(status: 'sent').each do |delivery|
  puts delivery.error_message
end
```

### 8.3 로그 확인

```bash
# Discord 관련 로그
tail -f log/development.log | grep -i discord
```

---

## 9. 배포

### 9.1 프로덕션 환경 변수 설정

```bash
# 배포 서버 환경 변수
export DISCORD_CLIENT_ID=production_client_id
export DISCORD_CLIENT_SECRET=production_client_secret
export DISCORD_BOT_TOKEN=production_bot_token
```

### 9.2 프로덕션 Redirect URI

Discord Developer Portal에 프로덕션 URI 추가:
```text
https://your-production-domain.com/discord/oauth/callback
```

### 9.3 프로덕션 봇 초대

프로덕션 봇을 사용자 서버에 초대하는 링크 제공.

---

## 10. 참고 자료

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord API Documentation](https://discord.com/developers/docs/intro)
- [discordrb-webhooks Gem](https://github.com/meew0/discordrb)
- [Discord Webhooks Guide](https://discord.com/developers/docs/resources/webhook)

---

## 추가 정보

### 데이터베이스 스키마

**notification_channels** (DiscordChannel)
- `type`: "DiscordChannel" (STI)
- `status`: active/inactive/error
- `remote_id`: Discord 채널 ID
- `name`: 서버/채널 이름
- `webhook_url`: 웹훅크 URL
- `channel_id`: 채널 ID
- `channel_name`: 채널 이름
- `metadata`: 추가 정보 (JSONB)

**notification_deliveries** (DiscordDelivery)
- `type`: "DiscordDelivery" (STI)
- `article_id`: 아티클 ID
- `notification_channel_id`: 채널 ID
- `status`: sent/failed
- `message_id`: Discord 메시지 ID
- `error_message`: 에러 메시지
- `metadata`: 추가 정보 (JSONB)

### 액션 흐름

1. 사용자가 `/discord/install` 접속 → Discord OAuth2
2. 콜백 처리 → 채널 목록 표시
3. 사용자가 채널 선택 → 웹훅크 생성 및 저장
4. 새 아티클 생성 → `DiscordArticleDeliveryJob` 큐에 추가
5. Job 실행 → `DiscordArticleNotifierService` 호출
6. 웹훅크 전송 → 배달 상태 저장
