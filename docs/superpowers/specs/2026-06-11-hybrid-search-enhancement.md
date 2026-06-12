# 하이브리드 검색 강화 설계

- 작성일: 2026-06-11
- 상태: 승인됨 (Tier 1 구현 대기)

## 배경

`feature/hybrid-search`에서 벡터(임베딩) + FTS를 RRF로 병합하고 코사인 임계값 필터·MMR
재순위를 더한 하이브리드 검색 엔진을 도입했다. 이제 검색 품질을 측정하고, 파라미터를
데이터 기반으로 튜닝하며, 검색 경험을 더욱 개선할 수 있는 기반을 구축한다.

## 접근: Tier 기반 점진적 강화

Tier 1(지금)·Tier 2(중기)·Tier 3(장기)로 나누어 각 단계가 독립적으로 검증 가능하도록 한다.
본 문서는 Tier 1 스펙을 완전히 정의하고, Tier 2·3은 방향성 수준으로 제시한다.

---

## Tier 1 — 파라미터 튜닝·품질 측정·검색어 제안

### 1.1 파라미터 외부 설정화

현재 `Articles::HybridSearch`의 상수들은 클래스 내부에 하드코딩되어 있다.
`config/hybrid_search.yml`로 분리해 환경별 튜닝과 A/B 테스트를 가능하게 한다.

**대상 상수:**

| 상수 | 현재값 | 설명 |
|---|---|---|
| `CANDIDATE_POOL` | 100 | 후보 풀 크기 |
| `RRF_K` | 60 | RRF 평탄화 계수 |
| `COSINE_THRESHOLD` | 0.6 | 코사인 유사도 하한 |
| `MMR_LAMBDA` | 0.7 | MMR 관련성 vs 다양성 가중치 |
| `EMBED_CACHE_TTL` | 12h | 임베딩 캐시 TTL |

**설계:**
```yaml
# config/hybrid_search.yml
default: &default
  candidate_pool: 100
  rrf_k: 60
  cosine_threshold: 0.6
  mmr_lambda: 0.7
  embed_cache_ttl: 43200  # 12 hours in seconds
```

`Articles::HybridSearch`가 `Rails.application.config_for(:hybrid_search)`로 읽고,
폴백으로 기존 하드코딩 값을 유지한다.

### 1.2 검색 품질 측정 (MRR 벤치마크)

검색 품질을 객관적으로 측정할 수 있는 오프라인 평가 프레임워크를 도입한다.

**요구사항:**
- `rake search:benchmark` — FTS-only vs Hybrid MRR 비교 리포트
- 평가 데이터: `test/fixtures/search_eval_queries.yml` (50개 내외의 쿼리-정답 쌍)
- 메트릭: MRR(Mean Reciprocal Rank), NDCG@10, Recall@10
- 리포트: 마크다운 또는 콘솔 테이블 형식

**평가 쿼리 형식:**
```yaml
# test/fixtures/search_eval_queries.yml
ruby_performance:
  query: "Ruby 성능 최적화"
  relevant_ids:
    - <%= ActiveRecord::FixtureSet.identify(:ruby_article) %>
metrics:
  query: "rails metrics monitoring"
  relevant_ids:
    - <%= ActiveRecord::FixtureSet.identify(:ruby_article) %>
```

**구현:**
```ruby
# lib/tasks/search_benchmark.rake
namespace :search do
  desc "Compare FTS-only vs Hybrid search quality (MRR, NDCG, Recall)"
  task benchmark: :environment do
    # 평가 쿼리 로드 → FTS-only 실행 → Hybrid 실행 → 메트릭 계산 → 리포트 출력
  end
end
```

### 1.3 검색어 유사도 기반 제안 (pg_bigm)

`pg_bigm` 확장의 `similarity()` 함수를 활용해, 검색 결과가 0건이거나 적을 때
유사한 검색어를 제안한다.

**구현:**
```ruby
# app/functions/articles/search_suggestions.rb
module Articles
  module SearchSuggestions
    module_function

    # 검색 결과가 적을 때 유사 검색어 제안
    def suggest(query, limit: 5, threshold: 0.3)
      return [] if query.blank?

      Article.joins(:pg_search_document)
             .where("pg_search_documents.content % ?", query)
             .order(Arel.sql("similarity(pg_search_documents.content, #{Article.connection.quote(query)}) DESC"))
             .limit(limit)
             .pluck(:title_ko, :title)
             .flatten
             .compact
             .uniq
             .first(limit)
    end
  end
end
```

**호출부 통합:**
- `ArticlesController#index` — 검색 결과가 `@articles.empty?`일 때 `@suggestions` 전달
- `Views::Articles::Index` — 제안 UI 표시 (Phlex 컴포넌트)

---

## Tier 2 — 벡터 인프라·쿼리 이해 (향후)

### 2.1 Cosine HNSW 인덱스 추가

현재 HNSW는 `vector_l2_ops`(euclidean)만 존재. Cosine distance용 인덱스를 병행 운영해
`nearest_neighbors(distance: "cosine")`가 인덱스를 타도록 한다.

### 2.2 쿼리 확장 (LLM)

사용자 쿼리를 `RubyLLM`으로 확장(동의어·관련어·한영 변형)해 재현율을 높인다.
FTS+벡터 양쪽에 benefit이 있으며, 확장 결과는 Solid Cache로 캐싱한다.

### 2.3 메타데이터 필터 + 하이브리드 검색

사이트·태그·기간 필터를 `HybridSearch`에 추가해 프리필터링으로 정밀도를 올린다.

### 2.4 Cross-Encoder 재순위

MMR 이후 상위 N개에 대해 heavier한 cross-encoder 모델을 적용하는 2단계 재순위.
RubyLLM이 rerank API를 지원할 때 도입.

---

## Tier 3 — 청킹·에이전트 (향후)

### 3.1 문서 청킹 (ArticleChunk)

기사 단위 1벡터(1536차원)의 한계를 넘어 문단/섹션 단위로 청킹.
검색: 청크 검색 → small-to-big → 상위 기사 복원.

### 3.2 에이전트 검색 도구 루프

`SearchRelatedArticles`를 넘어, LLM이 다단계 검색 전략을 스스로 수립하는
`SearchKnowledgeBase`, `FetchDocumentSection`, `ListAvailableSources` 도구 체인.

### 3.3 Turbo Streams 실시간 검색 UI

검색어 입력마다 Turbo Stream으로 결과를 스트리밍 교체.
검색 중간 상태(embedding... → searching... → ranked)를 단계별로 표시.

---

## Tier 1 테스트 전략

| 컴포넌트 | 테스트 종류 | 검증 내용 |
|---|---|---|
| `config/hybrid_search.yml` | 설정 로드 단위 테스트 | 전체 키 존재, 기본값 폴백, 환경별 오버라이드 |
| `Articles::HybridSearch` | 기존 테스트 확장 | config에서 상수 로드, config 키 누락 시 폴백 |
| `SearchBenchmark` | rake task 단위 테스트 | MRR 계산 정확성, 빈 결과 처리, 리포트 포맷 |
| `Articles::SearchSuggestions` | pg_bigm 의존 통합 테스트 | 유사도 임계값, 결과 수 제한, 빈 쿼리 처리 |

---

## 미해결/후속

- 평가 쿼리셋은 초기 20~30개에서 시작해 점진적으로 확장한다.
- `similarity()` 함수의 pg_bigm 의존성 — 확장 미설치 환경에서는 `SearchSuggestions`가
  `SQL::StatementInvalid`를 발생시키지 않도록 방어적으로 구현한다.
- Tier 2의 Cosine HNSW 인덱스는 pgvector 0.5.0+ 필요. 현재 버전 확인 후 마이그레이션.
