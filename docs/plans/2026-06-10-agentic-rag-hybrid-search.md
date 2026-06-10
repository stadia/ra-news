# 에이전틱 RAG: 하이브리드 검색 엔진 계획·스펙

> 원천: 기사 "RubyLLM과 Rails를 이용한 에이전틱 RAG 구축 가이드"
> 작성일: 2026-06-10 · 대상: AlNews (Rails 8.1 / RubyLLM 1.16)

Article 본문 코퍼스를 대상으로, LLM이 스스로 검색 전략을 결정하는
에이전틱 RAG를 점진적으로 구축한다. 본 문서는 **Increment 1(완료)**의 스펙과
**Increment 2~4(예정)**의 플랜을 함께 정리한다.

---

## 배경 / 설계 원칙

- **인프라는 이미 존재한다.** pgvector 확장, `neighbor` 1.2.0 젬,
  `articles.embedding vector(1536)` 컬럼, HNSW 인덱스, `RubyLLM.embed`
  프로덕션 호출 패턴(`gemini-embedding-001`, 1536차원)이 이미 깔려 있다.
  새 인프라를 만들지 않고 **검색 오케스트레이션**부터 쌓는다.
- **점진적 구현.** 검색 코어 → 에이전트 도구 루프 → UI 스트리밍 순으로
  각 단계가 독립적으로 검증 가능하도록 쪼갠다.
- **기존 검색 로직 재사용.** `pg_search`의 `full_text_search_for` 스코프,
  `neighbor`의 `nearest_neighbors`를 도구로 재사용해 복잡성을 낮춘다.

---

## Increment 1 — 하이브리드 검색 엔진 (RAG 코어) ✅ 완료

LLM 없이도 단독으로 동작·검증 가능한 6단계 하이브리드 검색 서비스.

### 스펙

`HybridSearchService.new.call(query, limit: 10) -> Dry::Monads::Result`

| Phase | 단계 | 구현 |
|------:|------|------|
| 1 | 쿼리 임베딩 | `RubyLLM.embed(query, model: "gemini-embedding-001", dimensions: 1536)`. SHA256 캐시키 + 1일 TTL |
| 2 | 전문검색 후보 | `Article.kept.confirmed.full_text_search_for(query).limit(30)` 순위 리스트 |
| 3 | 벡터 후보 | `nearest_neighbors(:embedding, vec, distance: "cosine").limit(30)`, id→cosine_similarity 보존 |
| 4 | RRF 병합 | Reciprocal Rank Fusion, `score = Σ 1/(k + rank)`, k=60 |
| 5 | 임계값 필터 | cosine similarity < 0.5 제거 (전문검색-only id는 보수적 통과) |
| 6 | MMR 재랭킹 | `λ·sim(q,d) − (1−λ)·max sim(d,선택됨)`, λ=0.5, 최종 10개 |

**반환:** 성공 시 MMR 정렬된 `Article` 레코드 배열(`kept.confirmed` 유지).
실패 시 `:blank_query | :embedding_failed | :fulltext_failed | :vector_failed | :no_candidates | :rerank_failed`.

**노출 상수(전역 튜닝):** `RRF_K=60`, `MMR_LAMBDA=0.5`,
`VECTOR_CANDIDATES=30`, `FULLTEXT_CANDIDATES=30`, `SIMILARITY_THRESHOLD=0.5`,
`RESULT_LIMIT=10`, `EMBED_MODEL`, `EMBED_DIMENSIONS`.

### 확정 의사결정

| 항목 | 결정 | 사유 |
|------|------|------|
| 청킹 | 기사단위 유지(`articles.embedding`) | 범위 최소화. 청킹은 Increment 3 |
| 거리 함수 | cosine | Phase 5 코사인 임계값 요구 |
| 병렬성 | 순차 실행 | DB 풀 안전. 진짜 병렬화는 후속 |
| 임베딩 차원/모델 | 1536 / `gemini-embedding-001` 고정 | 컬럼·인덱스·기존 데이터와 일치 |

### 산출물

| 파일 | 역할 |
|------|------|
| `app/services/hybrid_search_service.rb` | 6단계 ROP 파이프라인 (`< OperationService`) |
| `app/functions/articles/search_ranking.rb` | 순수 함수: RRF / cosine / MMR |
| `test/services/hybrid_search_service_test.rb` | 서비스 테스트 11개 (RubyLLM.embed stub) |
| `test/functions/articles/search_ranking_test.rb` | 순수함수 단위 테스트 11개 |

**검증:** validate(level=rails) 4/4 OK · 테스트 22 runs / 56 assertions / 0 failures.

### 사용 예

```ruby
result = HybridSearchService.new.call("rails 8 비동기 쿼리")
articles = result.value_or([])   # => Array<Article>
```

---

## Increment 2 — 에이전트 도구 루프 (예정)

검색 서비스를 `RubyLLM::Tool`로 감싸 LLM이 스스로 호출하게 한다.

### 플랜

1. **`SearchKnowledgeBase` 도구** (`RubyLLM::Tool` 상속)
   - 내부에서 `HybridSearchService` 호출
   - `MAX_TOOL_CALLS` 예산으로 무한 루프 방지
2. **`FetchDocumentSection` 도구** — small-to-big 패턴.
   기사단위 검색 후 전후 맥락(요약/원문 일부) 확장.
   ※ 청킹(Increment 3) 도입 시 청크→상위섹션 확장으로 강화.
3. **`ListDocuments` 도구** — 검색 가능한 소스 오리엔테이션(사이트/태그/기간).
4. **`Note` 도구** — 에이전트 추론 기록(최종 답변 미포함, 디버깅용).
5. **에이전트 루프 Job** — Active Job(solid_queue) 백그라운드 실행.
   **비영속 `RubyLLM::Chat`** 객체로 루프 실행 → 중간 메시지 DB 미저장,
   최종 답변·인용·단계 기록만 메타데이터로 일괄 저장.

### 스펙 초안

- 진입점: `RagAgentService.new.call(question)` 또는 `RagAgentJob.perform_later(...)`
- 예산: `MAX_TOOL_CALLS`(예 8), 타임아웃
- 출력: `{ answer:, citations: [article_id...], steps: [...] }`

---

## Increment 3 — 청킹 (ArticleChunk) (예정)

기사단위 1벡터 → 청크 단위 임베딩으로 RAG 정밀도 향상.

### 플랜

- `ArticleChunk` 모델 + 테이블: `article_id`, `content:text`,
  `position:integer`, `embedding:vector(1536)`, HNSW 인덱스
- 청킹 전략(문단/토큰 기준) + 백필 Job
- `HybridSearchService` 벡터 단계를 청크 검색으로 전환,
  small-to-big로 상위 기사/섹션 복원
- 기존 `articles.embedding`은 유사기사(related) 용도로 유지/공존 결정

---

## Increment 4 — Turbo Streams 실시간 스트리밍 (예정)

에이전트 진행 단계를 사용자에게 실시간 노출.

### 플랜

- 에이전트 Job에서 단계별 Turbo Stream broadcast
  ("🔍 검색 중…", "💭 추론 중…", 최종 답변)
- 질의 UI(Phlex 뷰 + RubyUI 컴포넌트), Stimulus 컨트롤러
- i18n: `config/locales/ko.yml` 단계 라벨

---

## 횡단 후속 TODO

| # | 항목 | 영향 | 우선순위 |
|---|------|------|---------|
| a | cosine용 `vector_cosine_ops` HNSW 인덱스 추가 | 현재 L2 인덱스라 cosine 정렬이 순차 스캔. 코퍼스 커지면 성능 저하 | 코퍼스 규모 커지기 전 |
| b | 청킹(ArticleChunk) | RAG 정밀도 | Increment 3 |
| c | Phase 2 & 3 진짜 병렬화 | 레이턴시. DB 풀 크기 확인 필요 | 트래픽 발생 시 |
| d | 쿼리 임베딩 캐시 정책 검토 | solid_cache TTL/무효화 | 운영 중 |

---

## 운영 메모

- **환경변수:** `GEMINI_API_KEY` 필수(쿼리 임베딩). 미설정 시 `:embedding_failed`.
- **스코프 일관성:** 모든 DB 진입점에 `kept.confirmed` 적용(삭제/미확정 기사 제외).
- **TOAST 주의:** `body`/`embedding`은 TOAST 컬럼. 후보 단계는 `pluck(:id)`,
  MMR 단계에서만 embedding 포함 로드.
- **테스트:** `RubyLLM.embed`는 반드시 stub(실 API 호출 금지). 픽스처에
  embedding 부재 → DB 의존 경로는 통합 환경에서 별도 확인.
