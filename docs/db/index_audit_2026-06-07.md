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

## 2. 목적 불명 인덱스 (조사 필요)

### `articles.index_articles_on_deleted_at_and_slug_and_title_ko_and_id`

4컬럼 복합 인덱스 `(deleted_at, slug, title_ko, id)`:

- `slug`는 이미 `index_articles_on_slug` (unique) 존재
- `deleted_at` prefix 시작이어서 일반 lookup 에는 비효율
- 어떤 쿼리/스코프가 이 인덱스를 사용하는지 불명

조치안:
1. 운영 DB 에서 `pg_stat_user_indexes` 로 `idx_scan` 확인
2. 코드베이스에서 `deleted_at`, `slug`, `title_ko`, `id` 4개 조합 WHERE 절 사용처 grep
3. 사용처 없으면 별도 마이그레이션으로 제거

## 3. 보류된 인덱스 추가 후보

| 테이블 | 컬럼 | 사유 | 비고 |
|---|---|---|---|
| `articles` | `is_posted` | 잡 스캔에서 `WHERE is_posted = false` 자주 사용 시 | partial index (`WHERE is_posted = false`) 권장. 실제 쿼리 패턴 확인 후 결정 |

## 4. 보류된 Foreign Key 추가

전부 인덱스는 이미 있지만 FK 제약은 없다. 추가 전 고아 데이터 검증이 필요하다.

### 4-1. 안전한 nullable FK (검증 후 즉시 추가 가능)

```sql
-- 추가 전 고아 데이터 확인 쿼리
SELECT COUNT(*) FROM articles WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);
SELECT COUNT(*) FROM articles WHERE federails_actor_id IS NOT NULL AND federails_actor_id NOT IN (SELECT id FROM federails_actors);
SELECT COUNT(*) FROM posts WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);
SELECT COUNT(*) FROM posts WHERE federails_actor_id IS NOT NULL AND federails_actor_id NOT IN (SELECT id FROM federails_actors);
SELECT COUNT(*) FROM posts WHERE parent_id IS NOT NULL AND parent_id NOT IN (SELECT id FROM posts);
```

| 테이블 | 컬럼 | 참조 | 권장 on_delete |
|---|---|---|---|
| `articles` | `user_id` | `users.id` | `:nullify` |
| `articles` | `federails_actor_id` | `federails_actors.id` | `:nullify` |
| `posts` | `user_id` | `users.id` | `:nullify` |
| `posts` | `federails_actor_id` | `federails_actors.id` | `:nullify` |
| `posts` | `parent_id` | `posts.id` (self) | `:nullify` 또는 `:cascade` 검토 |

### 4-2. 위험한 FK (데이터 정합성 작업 선행 필요)

| 테이블 | 컬럼 | 참조 | 위험 요소 |
|---|---|---|---|
| `articles` | `site_id` | `sites.id` | NOT NULL + default 0. `site_id = 0` 인 row 존재 가능. 정리 마이그레이션 선행 필수 |

```sql
SELECT COUNT(*) FROM articles WHERE site_id = 0 OR site_id NOT IN (SELECT id FROM sites);
```

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
