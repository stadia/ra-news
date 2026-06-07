# DB 인덱스/FK 감사 — 2026-06-07

본 문서는 인덱스/외래키 점검 결과 중 **이번 라운드에 처리하지 않은 항목**을 추적용으로 정리한 것이다.
이번 라운드(2026-06-07)에는 아래 기준만 적용했다:

- 자체 도메인 테이블의 명백한 중복 인덱스 제거
- 누락된 운영 인덱스(soft delete, role.name) 추가
- gem이 만든 인덱스/스키마는 유지
- FK 추가는 전부 보류

처리 마이그레이션: `db/migrate/20260607000000_cleanup_duplicate_indexes_and_add_missing.rb`

---

## 1. 보류된 중복 인덱스 (gem 소유)

다음 인덱스들은 prefix-cover 로 사실상 중복이지만, gem이 직접 생성/관리하므로 손대지 않는다.
gem 업그레이드 시 충돌을 피하기 위함이다.

| 테이블 | 인덱스 | 커버하는 인덱스 | 소유 gem |
|---|---|---|---|
| `federails_blocks` | `index_federails_blocks_on_actor_id` | `(actor_id, target_actor_id)` unique | federails |
| `federails_followings` | `index_federails_followings_on_actor_id` | `(actor_id, target_actor_id)` unique | federails |
| `federails_featured_items` | `index_federails_featured_items_on_actor_id` | `(actor_id, federated_url)` unique | federails |
| `federails_featured_tags` | `index_federails_featured_tags_on_actor_id` | `(actor_id, name)` unique | federails |
| `pg_search_documents` | `index_pg_search_documents_on_searchable` | `(searchable_type, searchable_id, created_at)` | pg_search |
| `friendly_id_slugs` | `index_friendly_id_slugs_on_slug_and_sluggable_type` | `(slug, sluggable_type, scope)` unique | friendly_id |
| `taggings` | `index_taggings_on_taggable_id`, `index_taggings_on_taggable_type`, `index_taggings_on_taggable_type_and_taggable_id` 등 다수 | 여러 복합 인덱스 | acts_as_taggable_on |

향후 조치 옵션:
- gem 마이그레이션을 추적해 next major 버전에서 정리되는지 확인
- 운영 환경 `pg_stat_user_indexes` 로 미사용(idx_scan = 0) 인덱스 식별 후 별도 안건으로 재논의

## 2. 목적 불명 인덱스 — 결론: 의도된 partial index, 유지

### `articles.index_articles_on_deleted_at_and_slug_and_title_ko_and_id`

조사 결과: `db/migrate/20251024144552_optimize_articles_index_for_slug_title.rb` 가 생성한
**partial index** (스키마 introspection 출력에서 WHERE 절이 누락되어 오해함):

```ruby
where: "deleted_at IS NULL AND slug IS NOT NULL AND title_ko IS NOT NULL"
```

`Article.kept.confirmed` 스코프와 정확히 매칭되며 다음 호출 경로에서 사용된다:

- `SocialPostJob` — `scope.confirmed.where(is_posted: false).where(created_at: ...).limit(4)`
- `SlackNotifier`, `DiscordNotifier` — `article.slug.present? && article.title_ko.present?` 가드
- `ArticleAgentsService`, `SocialMediaService` — `confirmed` 형태 조회

→ **유지 결정**. 이번 라운드 처리 안 함.

## 3. 보류된 인덱스 추가 후보

| 테이블 | 컬럼 | 결정 | 사유 |
|---|---|---|---|
| `articles` | `is_posted` | **추가 안 함** | 1) `is_posted = false` 비중이 60% (4180/6917) 로 partial index cardinality 효과 미미. 2) 호출 경로(`SocialPostJob`)는 `kept + confirmed` 조건이 먼저 걸려 위 4컬럼 partial index가 이미 cover. 3) `LIMIT 4` 로 결과 크기 작음. |

## 4. Foreign Key 추가 — 완료

처리 마이그레이션: `db/migrate/20260607010000_add_foreign_keys_for_articles_and_posts.rb`

고아 데이터 사전 검증 결과 (2026-06-07 시점):

| 컬럼 | 고아 row | 처리 |
|---|---|---|
| `articles.user_id` | 0 | FK 즉시 추가 (`on_delete: :nullify`) |
| `articles.federails_actor_id` | 0 | FK 즉시 추가 (`on_delete: :nullify`) |
| `posts.user_id` | 0 | FK 즉시 추가 (`on_delete: :nullify`) |
| `posts.federails_actor_id` | 0 | FK 즉시 추가 (`on_delete: :nullify`) |
| `posts.parent_id` | 0 | FK 즉시 추가 (self-ref, `on_delete: :nullify`) |
| `articles.site_id` | **307** | nullable 전환 + 307건 NULL 처리 + FK (`on_delete: :nullify`) |

### `articles.site_id` 변경 사항

- `NOT NULL default 0` → `NULL` 허용
- `site_id = 0` 또는 dangling 인 307건을 `NULL` 로 업데이트
- `belongs_to :site, optional: true` 는 모델에 이미 선언되어 있어 코드 변경 불필요
- 코드 호출 경로 (`article.site&.name`, `article.site&.client`, `if article.site` 가드 등) 는 nil 대응 완료 상태

### 4-3. 추가 불가 (polymorphic)

| 테이블 | 컬럼 | 사유 |
|---|---|---|
| `taggings` | `taggable_*`, `tagger_*` | polymorphic |
| `pg_search_documents` | `searchable_*` | polymorphic |
| `active_storage_attachments` | `record_*` | polymorphic |
| `federails_activities` | `entity_*` | polymorphic |
| `federails_actors` | `entity_*` | polymorphic |

## 5. Soft delete + FK 결합 고려사항

`articles`, `sites`, `notification_channels` 가 soft delete (`deleted_at`) 패턴을 쓴다.
이 테이블이 부모가 되는 FK 의 `on_delete` 정책:

- 자식 입장에서 부모가 soft delete 되어도 FK는 정상 — 행이 실제 삭제될 때만 동작
- 따라서 자식 FK 는 `:restrict` (실수로 hard delete 막기) 또는 `:nullify` 모두 가능
- 일관성을 위해 본 프로젝트는 nullable 자식은 `:nullify`, NOT NULL 자식은 `:restrict` 로 통일 권장
