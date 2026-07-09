# IndexNow 확장 설계 — 기사 이벤트 기반 ping (두 도메인)

> 날짜: 2026-07-07
> 배경: Bing Webmaster Tools가 IndexNow 도입을 추천. 기존에 `ArticleBatchJob`에 부분 구현이 있었으나 (1) 배치 번역 플로우만 커버, (2) `ruby-news.dev`(ko)만 ping, (3) 키/호스트가 하드코딩 — 이 갭들이 Bing 추천 지속의 원인.

## 목표

기사가 공개되거나 의미 있게 변경될 때, ko(`.dev`)와 ja(`.jp`) 양쪽 호스트의 공개 URL을 IndexNow에 ping하여 Bing 외 IndexNow 호환 엔진이 신규/갱신 기사를 즉시 발견·색인하도록 한다.

## 비목표 (YAGNI)

- 포스트(Post)의 IndexNow ping — 본 설계 범위 아님.
- `.kr` 리다이렉트 오리진 ping — 리다이렉트 도메인은 제외.
- ping 재시도/백오프 인프라 — 배치 잡의 비재시도 정책과 일관되게 로그만.
- solid_queue unique/dedup gem 도입 — 기존 `Rails.cache`(solid_cache)로 디바운스.

## 아키텍처

### 새 컴포넌트

- **`IndexNowService`** (`app/services/index_now_service.rb`) — 호스트별 URL 리스트를 받아 IndexNow API로 POST. 기존 `ArticleBatchJob#ping_index_now`의 전송 로직을 이곳으로 이전(단일 진실의 원천).
- **`IndexNowJob`** (`app/jobs/index_now_job.rb`) — `article_id`와 `host`를 인자로 받아, 기사의 공개 URL을 계산해 `IndexNowService`로 전송. `ApplicationJob` 상속.

### 기존 컴포넌트 변경

- **`Article`** 모델 — `after_commit :enqueue_index_now` 콜백 추가. 의미 있는 속성 변경 + confirmed 상태일 때만, per-article+per-host 디바운스 캐시 잠금으로 `IndexNowJob`을 `wait: 30s` 예약.
- **`ArticleBatchJob`** — `ping_index_now` 프라이빗 메서드 삭제, 배치 끝에서 호스트별로 URL을 묶어 `IndexNowService` 직접 호출(배치는 일회성 흐름이라 잡 경유 않음).
- **`Hosts`** 모듈 — `INDEX_NOW_KEY` 상수 추가(기존 하드코딩 키 `187d5ed120cc45f8869b89302011d43a` 이관). `FOR_LOCALE`에서 파생된 호스트 목록 활용. credentials는 사용하지 않음(사용자 결정).
- **`public/187d5ed120cc45f8869b89302011d43a.txt`** — 동일 키값 그대로. 두 도메인이 같은 Rails 앱·같은 `public/` 공유하므로 `.jp`에서도 같은 파일 서빙(`config.host_authorization`이 `ruby-news.jp` 허용 중). **구현 중 확인 사항**: `https://ruby-news.jp/{key}.txt`가 실제 200 응답하는지.

### 데이터 흐름

```
Article 저장 (slug/title_ko/본문/published_at 변경 + confirmed)
  → after_commit enqueue_index_now
  → [Rails.cache 디바운스 잠금 per (article_id, host)]
  → IndexNowJob.set(wait: 30s).perform_later(article_id, host)
  → 30s 후 잡 실행: 호스트별 공개 URL 계산 + confirmed 재확인
  → IndexNowService.call(host:, urls: [url])
  → POST https://api.indexnow.org/IndexNow
```

## 콜백 게이팅 & 디바운스

### `Article#enqueue_index_now` (after_commit)

게이팅 조건 (모두 만족 시에만 enqueue 시도):

1. `kept?` (discarded 아님)
2. `confirmed?` — `slug.present? && title_ko.present?` (`scope :confirmed`와 동일)
3. 의미 있는 변경 — `saved_change_to_attribute?` 중 하나라도 true: `slug`, `title_ko`, `title`, 본문/콘텐츠 칼럼, `published_at`. **정확한 칼럼명은 구현 시 `rails 'ai:tool[model_details]' model=Article`로 확인.**

> `after_commit`은 커밋 후 실행되므로 `saved_changes` 사용. create 시에는 해당 속성들이 present로 저장된 경우에만 confirmed 진입으로 간주.

### 디바운스 (per `article_id` + `host`)

```ruby
hosts = ["ruby-news.dev", "ruby-news.jp"] # Hosts::FOR_LOCALE에서 파생
hosts.each do |host|
  lock_key = "index_now:enqueue:#{host}:#{article.id}"
  next if Rails.cache.exist?(lock_key)
  Rails.cache.write(lock_key, true, expires_in: 60.seconds)
  IndexNowJob.set(wait: 30.seconds).perform_later(article.id, host)
end
```

- 첫 이벤트: 잠금 설정 + 30s 지연 잡 예약.
- 30s 내 후속 이벤트: 잠금 존재 → enqueue 스킵(이미 예약된 잡이 30s 후 최신 상태로 ping → 자연 병합).
- 잡 `perform` 시: 잠금 키 삭제. ping 전송 후 성공/실패 로깅.
- 잡 `perform` 내부에서 기사가 더 이상 confirmed가 아니거나 discarded면(지연 중 삭제 등) 전송 스킵.

> `JobRateLimiting` concern은 카운터 기반 잡 내부 실행 빈도 제한용이고 enqueue 중복 제거에 부적합해 별도 캐시 잠금 사용.

## 서비스/잡 인터페이스

### `IndexNowService`

```ruby
#: (host: String, urls: Array[String]) -> void
def call(host:, urls:)
  return if urls.blank?
  key = Hosts::INDEX_NOW_KEY
  return if key.blank?
  key_location = "https://#{host}/#{key}.txt"
  payload = { host:, key:, keyLocation: key_location, urlList: urls }
  response = Faraday.post("https://api.indexnow.org/IndexNow", payload.to_json,
                          "Content-Type" => "application/json; charset=utf-8")
  if response.status.to_i.between?(200, 299) # 200 OK, 202 Accepted
    logger.info("IndexNow ping success: host=#{host} urls=#{urls.size}")
  else
    logger.error("IndexNow ping failed: host=#{host} status=#{response.status} body=#{response.body}")
  end
rescue StandardError => e
  logger.error("IndexNow ping error: host=#{host} #{e.class} - #{e.message}")
end
```

- 비재시도 정책 유지(배치 잡과 일관). 422/429 등도 로그만.

### `IndexNowJob`

```ruby
#: (Integer article_id, String host) -> void
def perform(article_id, host)
  article = Article.kept.find_by(id: article_id)
  return unless article
  return if article.slug.blank? || article.title_ko.blank?
  url = Rails.application.routes.url_helpers.article_url(article, host:, protocol: "https")
  IndexNowService.new.call(host:, urls: [url])
ensure
  Rails.cache.delete("index_now:enqueue:#{host}:#{article_id}")
end
```

> 인스턴스 `confirmed?` predicate는 없으므로(모델은 `scope :confirmed`만 제공) 잡 내부에서 `slug`/`title_ko` 인라인 검사로 confirmed 여부를 재확인한다.

- `article_id`(레코드가 아닌 id) 인자 — `discard_on RecordNotFound` 회피, 지연 중 삭제 케이스 안전.
- 명시적 `host:` 오버라이드로 로케일별 호스트 보장.

### `ArticleBatchJob` 변경

`ping_index_now` 삭제. 배치는 ko(`ruby-news.dev`)만 담당하므로, 배치 끝에서 `index_now_urls`(모두 `ruby-news.dev` URL)를 `IndexNowService.new.call(host: "ruby-news.dev", urls:)`로 직접 호출한다. `.jp` 호스트는 `Article` after_commit 콜백이 커버한다.

## 테스트 전략

Minitest(기존 `article_batch_job_test.rb`와 일치) + `rails 'ai:tool[generate_test]'` 활용.

- **`test/jobs/index_now_job_test.rb`** — confirmed → 서비스 호출(올바른 host/urls); unconfirmed → 호출 안 함; discarded/조회 실패 → 호출 안 함·예외 없음.
- **`test/services/index_now_service_test.rb`** — 빈 urls/빈 key → early return; Faraday stub 200/202 성공, 422 에러 로그, 예외 에러 로그+raise 안 함; `keyLocation` host 파생(.dev vs .jp).
- **`test/models/article_test.rb`** (IndexNow 부분) — confirmed 진입 → 호스트 수만큼 enqueue(wait: 30s); 의미 없는 변경 → enqueue 안 함; unconfirmed → enqueue 안 함; 디바운스 30s 내 두 번째 → 스킵.
- **`test/jobs/article_batch_job_test.rb`** (갱신) — `ping_index_now` stub → `IndexNowService` stub로 교체, 동작 동일.

## 검증

매 에디트 후 `rails 'ai:tool[validate]' files=...` + 테스트 러너 실행(메인 러너 Minitest vs RSpec 구현 시 확인).

## 구현 중 확인 사항

1. Article 의미 있는 변경 칼럼명 — `rails 'ai:tool[model_details]' model=Article`.
2. `https://ruby-news.jp/{key}.txt` 실제 200 응답 여부.
3. `article_url` 헬퍼가 `host:` 오버라이드 시 로케일 라우팅에 문제 없는지.
4. 메인 테스트 러너(Minitest `bin/rails test` vs `bundle exec rspec`).