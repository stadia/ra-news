# Flog 리팩토링 계획서

> views/components는 Flog 검사에서 제외됨 (`lib/quality/flog_parser.rb`)

## 현재 상태 (app code only)

| 게이트         | 현재값   | 목표(Phase 1) | 목표(Phase 2) | 최종 목표 |
|---------------|---------:|--------------:|--------------:|----------:|
| method_max    |    92.54 |            50 |            30 |        20 |
| class_max     |   288.16 |           150 |           100 |        70 |

## 상위 위반 (method 기준)

| 순위 | 점수   | 클래스                       | 메서드                              | 비고           |
|---:|------:|:-----------------------------|:------------------------------------|:---------------|
|  1 |  92.5 | Article                      | #none                              | gem 생성,수정불가 |
|  2 |  89.0 | HackerNewsSiteJob            | #perform                           |                |
|  3 |  88.9 | Post                         | .from_activitypub_object           |                |
|  4 |  77.4 | ArticlesController           | #show                              |                |
|  5 |  74.4 | RssSitePageJob               | #perform                           |                |
|  6 |  64.9 | ArticlesController           | #index                             |                |
|  7 |  63.8 | PushNotificationService      | #send_single                       |                |
|  8 |  62.3 | HomeController               | #index                             |                |
|  9 |  60.9 | ArticlesController           | #create                            |                |
| 10 |  56.0 | ArticleAgentsService         | #run_agents                        |                |
| 11 |  55.1 | SocialController             | #provider_callback                 |                |
| 12 |  53.6 | Post                         | .extract_body_from_activitypub_object |             |
| 13 |  52.7 | ArticleResource              | #none                              | gem 생성,수정불가 |
| 14 |  48.2 | Post                         | #none                              | gem 생성,수정불가 |
| 15 |  47.6 | DiscordController            | #callback                          |                |
| 16 |  46.0 | ContentService               | #execute_youtube                   |                |
| 17 |  44.6 | DiscordClient                | #post_embed                        |                |
| 18 |  42.9 | Article                      | .should_ignore_url?                |                |
| 19 |  42.7 | RssSiteJob                   | #perform                           |                |
| 20 |  42.4 | Post                         | #to_activitypub_object             |                |

## 상위 위반 (class 기준)

| 순위 | 점수    | 클래스                          | 메서드 수 | 최고 메서드 점수 |
|---:|-------:|:-------------------------------|-------:|-------:|
|  1 |  288.2 | ArticlesController             |     13 |   77.4 |
|  2 |  253.4 | Article                        |     17 |   92.5 |
|  3 |  229.7 | Articles::MetadataPreparation  |     18 |   27.5 |
|  4 |  187.1 | ArticleAgentsService           |      9 |   56.0 |
|  5 |  185.4 | ContentService                 |      9 |   46.0 |
|  6 |  176.8 | FollowingsController           |     18 |   34.4 |
|  7 |  170.5 | Post                           |     14 |   48.2 |
|  8 |  165.5 | PostsController                |     16 |   31.6 |
|  9 |  135.2 | Users::RegistrationsController |     16 |   39.3 |
| 10 |  113.8 | Articles::MetadataPreparationService | 7 | 29.2 |

## 분석: 병목 원인

### 1. gem 생성 `#none` 메서드 (수정 불가)
- `Article#none` (92.5), `ArticleResource#none` (52.7), `Post#none` (48.2)
- `acts_as_taggable_on` 등 gem이 생성하는 메서드
- **Flog 파서에서 gem 생성 메서드를 제외**하거나 threshold에서 감안 필요

### 2. 거대 퍼포머 (Job)
- `HackerNewsSiteJob#perform` (89.0): 스크래핑 → 파싱 → 저장 다단계 분기
- `RssSitePageJob#perform` (74.4): RSS 파싱 → 기사 생성 반복
- `RssSiteJob#perform` (42.7): RSS 피드 수집 → 페이지 분배

**해결 전략**: 각 단계를 private 메서드로 추출, 공통 로직은 concern으로

### 3. ActivityPub 직렬화/역직렬화
- `Post.from_activitypub_object` (88.9): JSON → 모델 매핑 + 검증 + 저장
- `Post.extract_body_from_activitypub_object` (53.6): 미디어 타입별 본문 추출
- `Post#to_activitypub_object` (42.4): 모델 → JSON 직렬화

**해결 전랙**: `ActivityPub::PostBuilder`, `ActivityPub::PostSerializer` 서비스 분리

### 4. Controller 액션 과다
- `ArticlesController` (288.2): show(77.4) + index(64.9) + create(60.9)
- `HomeController#index` (62.3): 쿼리 조합 + 렌더링 데이터 조립

**해결 전략**: 쿼리/조립 로직을 스코프나 서비스로 이동

### 5. 서비스 단일 메서드 과대
- `PushNotificationService#send_single` (63.8): 페이로드 빌드 + 전송 + 에러 처리
- `ContentService#execute_youtube` (46.0): 트랜스크립트 + 백업 전략

**해결 전략**: 단계별 메서드 추출, early return 가드

---

## Phase 1: method_max ≤ 50 / class_max ≤ 150

### 1.1 Flog 파서: gem `#none` 제외 (method_max: 92 → ~89)

| 작업                                | 파일                         |
|:------------------------------------|:-----------------------------|
| `#none` 메서드를 Flog 결과에서 필터 | `lib/quality/flog_parser.rb` |

Gem이 생성하는 `#none`은 앱 코드가 아니므로 제외하면 즉시 method_max가 89.0으로 하락.

### 1.2 HackerNewsSiteJob#perform (89.0 → ~25)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| 스크래핑 단계 추출             | `#fetch_hacker_news_content`      |
| 아티클 생성/업데이트 분리      | `#upsert_article_from_item`       |
| 에러 처리 정리                 | early return 가드                 |

### 1.3 Post.from_activitypub_object (88.9 → ~20)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| JSON → 모델 매핑 분리         | `ActivityPub::PostBuilder` 서비스 |
| 본문 추출 분리                | `#extract_body_from_activitypub_object` 정리 |
| 검증/저장 분리                | 빌더 내부 단계 메서드             |

### 1.4 ArticlesController (class: 288.2 → ~130)

| 액션          | 현재   | 목표  | 작업                                    |
|:--------------|------:|------:|:----------------------------------------|
| #show (77.4)  | → 25  | 쿼리를 스코프로, 렌더링 데이터를 서비스로 |
| #index (64.9) | → 25  | 필터/페이지네이션을 스코프로            |
| #create (60.9)| → 25  | 검증 → 중복확인 → 저장을 서비스로       |

### 1.5 RssSitePageJob#perform (74.4 → ~25)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| RSS 파싱 단계 추출            | `#parse_feed_entries`             |
| 기사 생성 반복 추출           | `#import_entry`                   |
| 공통 로직                     | `RssImportConcern`                |

### 1.6 PushNotificationService#send_single (63.8 → ~20)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| 페이로드 빌드 분리            | `#build_webpush_request`          |
| 구독 만료 처리 분리           | `#handle_expired_subscription`    |

### 1.7 HomeController#index (62.3 → ~20)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| 쿼리 조합을 스코프로          | Article 스코프 활용               |
| 렌더링 데이터 조립 분리       | private 메서드 추출               |

### 1.8 ArticleAgentsService#run_agents (56.0 → ~20)

| 작업                          | 기법                              |
|:------------------------------|:----------------------------------|
| 에이전트 실행 루프 분리       | `#run_single_agent`               |
| 에이전트 선택 로직 분리       | `#applicable_agents`              |

---

## Phase 2: method_max ≤ 30 / class_max ≤ 100

Phase 1 완료 후 재측정. 예상 대상:

| 대상                                    | 현재 점수 | 예상 작업                      |
|:----------------------------------------|------:|:-------------------------------|
| SocialController#provider_callback      |  55.1  | OAuth 단계별 분리              |
| Post.extract_body_from_activitypub_object | 53.6  | 미디어 타입별 메서드           |
| ContentService#execute_youtube          |  46.0  | 트랜스크립트 전략 패턴 도입    |
| DiscordClient#post_embed                |  44.6  | 임베드 빌더 분리               |
| RssSiteJob#perform                      |  42.7  | 1.5의 concern 재사용          |
| Post#to_activitypub_object              |  42.4  | 직렬화 서비스 분리            |
| Articles::MetadataPreparation (class)   | 229.7  | 모듈 분리 (URL/published_at)  |

---

## Phase 3: method_max ≤ 20 / class_max ≤ 70

최종 목표. Phase 2 이후 남은 중간 위반(20~30점대)을 세밀하게 분해.

---

## 작업 순서 (Phase 1)

```
1. Flog 파서 gem #none 제외       ← method_max 즉시 89로 하락
2. HackerNewsSiteJob#perform       ← method_max 직접 해소
3. Post.from_activitypub_object    ← class_max 7위 + method 3위
4. ArticlesController              ← class_max 1위
5. RssSitePageJob#perform          ← method_max 5위
6. PushNotificationService         ← method_max 7위
7. HomeController#index            ← method_max 8위
8. ArticleAgentsService            ← class_max 4위
```

각 단계:
1. 해당 파일 Flog 상세 점수 확인
2. 추출할 메서드/서비스 설계
3. 리팩토링 적용
4. `bin/rails test` 회귀 확인
5. `bin/rake quality` Flog 재측정

## 위험 및 주의사항

- **`#none`은 gem 생성 메서드**: 직접 수정 불가, Flog 파서에서 제외 처리
- **Job 리팩토링 시 트랜잭션 경계 주의**: `perform` 내부의 트랜잭션이 분리되면 원자성 깨질 수 있음
- **ActivityPub 직렬화는 프로토콜 계약**: 구조 변경 시 연동 서버와 호환성 검증 필요
- **서비스 분리 시 순환 의존성 주의**: 컨트롤러 → 서비스 → 모델 방향 유지
