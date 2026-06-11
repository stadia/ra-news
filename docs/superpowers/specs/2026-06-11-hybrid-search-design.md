# Articles 하이브리드 검색 설계

- 작성일: 2026-06-11
- 상태: 승인됨 (구현 대기)

## 배경

현재 AlNews의 검색/유사도는 세 군데에서 단독 신호만 사용한다.

| 위치 | 현재 방식 | 문제 |
|---|---|---|
| `/articles?search=` (`Articles::Query#index_html`) | FTS 단독 (`full_text_search_for`) | 의미 기반(동의어·개념) 재현율 부족 |
| 글 상세 "유사 글" (`ArticlesController#show`) | 벡터 단독 (`nearest_neighbors`, euclidean, 4건) | 본 설계 범위 외 (이번에는 변경 안 함) |
| 에이전트 도구 `SearchRelatedArticles` | 벡터 OR 텍스트 (택일) | 두 신호를 병합하지 않음 |

목표: **벡터(임베딩) 검색 + 전문 검색(FTS)** 을 RRF로 병합하고, 임계값 필터·MMR 재순위를 더한
하이브리드 검색 엔진을 도입한다. 메인 검색과 에이전트 도구에 연결한다.

기존 인프라(재사용):
- `articles.embedding` `vector(1536)` + HNSW 인덱스(`vector_l2_ops` = euclidean), `has_neighbors :embedding`
- 임베딩 생성 파이프라인: `ArticleAgentsService#run_embed` → `RubyLLM.embed(model: "gemini-embedding-001", dimensions: 1536)`
- FTS: `Article.full_text_search_for(term)` (textsearch_ko + pg_bigm 하이브리드, ko/ja 분기 포함)
- 캐시: Solid Cache (`config.cache_store = :solid_cache_store`)

## 적용 범위

포함:
- 하이브리드 검색 엔진 (벡터 + FTS → RRF → 임계값 → 선택적 MMR)
- 메인 검색(`/articles?search=`) 연결
- 에이전트 도구 `SearchRelatedArticles`의 `query` 경로 연결

제외:
- 글 상세 페이지의 "유사 글"(`@similar_articles`) — 현재 벡터 단독 유지
- 에이전트 루프/Tool 추가, Turbo Streams 실시간 단계 UI 등 풀 에이전틱 RAG

## 아키텍처

접근 A(레이어 분리)를 채택한다. 융합 프리미티브를 순수 함수로 분리해 DB 없이 단위 테스트하고,
오케스트레이터가 이를 조합한다. 프로젝트의 기존 `app/functions/`(상태 없는 쿼리 로직)·`app/tools/` 패턴에 부합한다.

```
app/functions/search/reciprocal_rank_fusion.rb     # 순수 함수: 여러 순위 ID 리스트 → 융합 순위
app/functions/search/maximal_marginal_relevance.rb # 순수 함수: (쿼리벡터, 후보벡터들, λ) → 다양성 재순위
app/functions/articles/hybrid_search.rb            # 오케스트레이터
```

기각한 대안:
- 접근 B(단일 서비스에 private rrf/mmr): 융합 로직 재사용·독립 테스트 불가, 관심사 혼합.
- 접근 C(호출부 인라인): 중복·테스트 불가, "하나의 명확한 목적" 위배.

## 컴포넌트 인터페이스

### `Search::ReciprocalRankFusion`

순수 함수. 점수 정규화 없이 순위만으로 병합한다.

```
Search::ReciprocalRankFusion.call(ranked_lists, k: 60) -> Array[id]
# ranked_lists: Array[Array[id]]  (각 리스트는 순위 내림차순으로 정렬된 ID 배열)
# 반환: 융합 점수 내림차순 ID 배열 (중복 제거)
# score(id) = Σ_over_lists 1.0 / (k + rank)   (rank: 0부터)
```

- 입력 리스트 중 빈 리스트는 무시한다.
- 동점 시 입력 등장 순서를 안정적으로 유지한다.

### `Search::MaximalMarginalRelevance`

순수 함수. 관련도와 다양성의 균형으로 재순위한다.

```
Search::MaximalMarginalRelevance.call(query_vector:, candidates:, lambda: 0.7, limit:) -> Array[id]
# candidates: Array[{ id:, vector: Array[Float] }]   (RRF 통과 후보, 임베딩 포함)
# 매 단계 argmax: λ·cos(query, d) − (1−λ)·max_{s∈selected} cos(d, s)
# 반환: 선택 순서대로의 ID 배열 (최대 limit개)
```

- 코사인 유사도는 내부 헬퍼로 계산(0 벡터 방어: 분모 0이면 유사도 0).
- 후보가 `limit` 이하이면 MMR 순서대로 전부 반환.

### `Articles::HybridSearch`

```
Articles::HybridSearch.call(query:, limit: 20, mmr: false) -> Array[Integer]  # Article id, 순위순
```

데이터 흐름:
1. **정규화/가드** — `query` blank이면 `[]` 반환.
2. **Embed** — 정규화 쿼리(`query.strip.downcase`)를 캐시 키로 Solid Cache 조회. 미스 시
   `RubyLLM.embed(query, model: "gemini-embedding-001", dimensions: 1536).vectors.to_a` 후 `EMBED_CACHE_TTL`(12h) 저장.
   API 실패/타임아웃 → 로그 경고 후 `embedding = nil` 로 진행(FTS 단독 폴백).
3. **벡터 검색** — 임베딩이 있으면
   `Article.kept.confirmed.nearest_neighbors(:embedding, qvec, distance: "euclidean").limit(CANDIDATE_POOL)` → `[id, neighbor_distance]`.
   임베딩이 없으면 벡터 리스트는 빈 배열.
4. **FTS 검색** — `Article.kept.confirmed.full_text_search_for(query).limit(CANDIDATE_POOL).pluck(:id)`.
5. **RRF 병합** — `ReciprocalRankFusion.call([vector_ids, fts_ids], k: RRF_K)`.
6. **임계값 필터** — 벡터 출신 후보 중 `cos(query, candidate) < COSINE_THRESHOLD`(0.6) 제거.
   FTS 매칭 후보(벡터 리스트에 없던 ID)는 통과. 후보 풀 임베딩은 한 번만 로드해 코사인 계산 및 MMR에 공유.
7. **MMR(선택)** — `mmr: true`이면 `MaximalMarginalRelevance.call(...)`로 재순위. false면 RRF 순서 유지.
8. 상위 `limit` ID 반환.

상수(튜닝용, 클래스 내부):
```
CANDIDATE_POOL = 100
RRF_K = 60
COSINE_THRESHOLD = 0.6
MMR_LAMBDA = 0.7
EMBED_CACHE_TTL = 12.hours
```

거리 메트릭: HNSW 인덱스가 `vector_l2_ops`(euclidean)이므로 `nearest_neighbors`는 euclidean 그대로 사용한다.
임계값/MMR의 코사인 유사도만 Ruby에서 후보 임베딩으로 직접 계산한다(인덱스 변경 없음).

## 호출부 통합

### `Articles::Query#index_html`

```ruby
def index_scope(search)
  if search.present?
    ids = Articles::HybridSearch.call(query: search, limit: HYBRID_LIMIT)
    base_scope.where(id: ids).in_order_of(:id, ids).includes(*DEFAULT_INCLUDES).without_toast
  else
    base_scope.related.includes(*DEFAULT_INCLUDES).without_toast
  end
end
```

- `HYBRID_LIMIT`은 메인 검색에서 `CANDIDATE_POOL`(100)과 동일하게 둔다 — 후보 전체를 pagy가 페이지네이션하도록.
- 빈 결과(`ids == []`) → `base_scope.where(id: [])` = 빈 관계.
- 후보 풀(100)이 페이지네이션 상한이 된다. 검색 심층 페이지는 거의 사용되지 않으므로 수용.
- 컨트롤러의 `.order(published_at: :desc)`가 `in_order_of`의 RRF 순서를 덮어쓰므로, **검색 분기에서는 재정렬을 적용하지 않도록** `ArticlesController#index`를 조정한다(검색일 때 `.order` 생략, 비검색일 때만 `published_at` 정렬).
- 메인 검색은 `mmr: false`(관련도 순서 유지).

### `SearchRelatedArticles` 도구

```ruby
def search_by_text(query, limit)
  ids = Articles::HybridSearch.call(query:, limit:, mmr: true)
  Article.kept.confirmed.where(id: ids).in_order_of(:id, ids)
         .select(:id, :title_ko, :slug, :summary_key)
         .map { format_result(it) }
end
```

- `article_id`만 주어진 경로(`search_by_embedding`)는 기존 벡터 NN 유지(쿼리 임베딩 불필요).
- `query` 경로만 하이브리드로 교체하며 `mmr: true`로 중복 주제를 줄인다.

## 에러 처리

- 임베딩 API 실패/타임아웃 → 로그 경고 + FTS 단독 폴백. 검색은 항상 동작한다.
- 빈 쿼리 → 빈 결과(기존 동작 유지).
- 임베딩 없는 글 → 벡터 후보에서 자연 제외, FTS가 커버.
- 0 벡터/차원 불일치 → 코사인 유사도 0 처리(예외 발생 금지).

## 테스트 전략

- `Search::ReciprocalRankFusion` — DB 없는 순수 단위 테스트(고정 리스트로 융합 순서·동점 안정성·빈 리스트 처리).
- `Search::MaximalMarginalRelevance` — 고정 벡터로 다양성 선택·limit 경계·0 벡터 방어.
- `Articles::HybridSearch` — `RubyLLM.embed` stub, 픽스처 글로 RRF 순서·임베딩 실패 폴백·임계값 필터·캐시 적중 검증.
- `Articles::Query` 검색 분기 — 하이브리드 ID가 `in_order_of`로 순서대로 복원되는지, 빈 결과 처리.

## 미해결/후속

- 임계값(0.6)·λ(0.7)·풀 크기(100)는 운영 데이터로 튜닝 필요. 상수로 노출.
- 향후 풀 에이전틱 RAG(Tool 루프·FetchSection·Turbo Streams 단계 UI)는 별도 스펙.
