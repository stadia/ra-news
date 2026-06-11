# RAG 강화 백로그 (취사선택 결과)

> 상태: **보류** — `feature/hybrid-search` 머지/릴리즈 후 진행
> 작성일: 2026-06-11
> 출처: RubyLLM/Rails Agentic RAG 가이드 4편 검토 후 취사선택

## 배경

`feature/hybrid-search` 브랜치에서 하이브리드 검색(벡터+FTS+RRF+cosine threshold+MMR)을
구현 완료한 상태에서, 외부 RAG 구축 가이드 4편을 검토하고 우리 프로젝트(뉴스 애그리게이터)에
필요한 항목만 취사선택했다.

핵심 결론: **가이드의 6단계 하이브리드 검색 엔진과 에이전틱 도구 루프는 우리가 이미 보유**.
가이드의 RAG 본체(PDF 업로드/청킹 파이프라인, 사용자 Q&A 챗봇, 토큰 스트리밍 답변,
줌 패턴 인용 모달, Ollama/Voyage, K-means/Faiss 클러스터링)는 **도메인 불일치로 제외**.

## 도입하기로 한 항목 (우선순위 순)

선택: **A, C, D** / 제외: B(에이전트 도구 호출 예산 — 필요성 낮다고 판단)

진행 순서 확정: **A 단독 먼저** → 이후 D → 이후 C (각각 별도 spec→plan→구현 사이클)

### A. 기사 청킹 임베딩 (small-to-big + 시맨틱 청킹) — 최우선

- **근거 데이터**: 기사 본문 2000건 샘플 길이 분포
  - `p50=9,485 chars`, `p90=34,215`, `p99=98,244`, `max=501,261`
  - **약 54.4%가 임베딩 입력 한도 초과** (글자수/4 ≈ 토큰, >2048 기준의 보수적 하한)
- **gemini-embedding-001 확정 스펙**:
  - 최대 입력 **2,048 토큰**, 기본 차원 3,072 (우리는 1536으로 잘라 사용), 100+ 언어 지원
  - **초과 시 에러 없이 앞 2,048 토큰까지만 처리하고 뒷부분은 silent truncation**
- **함의 (중요)**: `run_embed`는 `article.body`를 자르지 않고 그대로 넘기며(`article_agents_service.rb:46`),
  truncation은 정상 응답이라 `rescue`에 안 걸리고 **로그·모니터링에 안 남는다**. 따라서
  본문 기사의 절반 이상이 지금까지 *조용히* 후반부를 잃은 채 임베딩됨 → 벡터 검색 누락.
- **ko/ja 보정**: 글자수/4는 영어 근사. ko/ja는 글자당 토큰이 더 많아 실제 초과율은
  54.4%보다 높을 가능성. A 착수 시 정확한 토크나이저/API usage로 ko/ja 보정 초과율 재측정할 것.
- **현재 구조**:
  - `articles.embedding` (1536차원, `gemini-embedding-001`) — 기사당 단일 벡터
  - 생성: `app/services/article_agents_service.rb` `run_embed` (body 기반, 단일)
  - 인덱스: HNSW `vector_l2_ops` (euclidean) — `index_articles_on_embedding`
  - 임베딩 norm ≈ 0.7로 거의 일정 (1536은 잘린 차원, L2 정규화 아님)
  - 사용처 2곳:
    1. 사용자 하이브리드 검색 벡터 후보 (`app/functions/articles/hybrid_search.rb` `vector_search`) — *쿼리 텍스트* 기반
    2. `SearchRelatedArticles` 관련 기사 추천 (`app/tools/search_related_articles.rb` `search_by_embedding`) — *article_id* 기반

#### 재개 시 먼저 결정할 미해결 설계 질문

1. **적용 범위** (스키마/마이그레이션 폭 결정):
   - (a) 메인 검색 벡터 후보만 청크 기반으로 교체, `SearchRelatedArticles`는 기존 단일 embedding 유지
   - (b) 검색 + 관련기사 둘 다 청크 기반
   - (c) `articles.embedding` 완전 제거하고 전부 청크 테이블로 이전
2. **청킹 전략**: 시맨틱(문단 경계 존중, ~500 토큰) vs 고정 토큰 vs 슬라이딩 윈도우.
   본문은 마크다운/HTML 혼재 가능성 — 전처리 고려.
3. **스키마**: `article_chunks` 신설안 (`article_id`, `chunk_index`, `content`, `embedding` + neighbor + HNSW). 기존 `articles.embedding` 유지/대표값/제거 여부.
4. **small-to-big 검색 통합**: 청크 벡터로 검색 → `article_id`로 dedup·환원 → 기존
   RRF/threshold/MMR 파이프라인은 article 단위 유지. "big"은 기사 전체.
5. **마이그레이션/백필**: 기존 기사 재임베딩 배치(비용·호출 수 증가). 청크당 1회 임베딩 호출.
6. **비용**: `gemini-embedding-001` 유지 가정. 청크 수만큼 임베딩 API 호출 증가.

### D. 검색 품질 평가 셋 (글2의 4 실패유형 관점)

- 출처: "RAG로 Ruby 전문가 LLM 구축" — 검색실패/청킹실패/컨텍스트압축/추론실패 분류.
- 현재 하이브리드 검색에 회귀 테스트는 있으나 "올바른 결과를 찾는가" 품질 메트릭 없음.
- A 도입 전후 검색 정밀도 비교(before/after)에 사용 → A와 묶어 진행하면 효과 측정 가능.

### C. 추론 기록 + 근거 확인 (글1 Note 도구 + 글2 자가검증)

- 출처: Agentic RAG 가이드의 Note 도구 + RAG 환각 관리 글의 인용/근거확인/자가평가.
- 현재 `app/functions/articles/agent_runner.rb` + `ArticleAgent`가 기사 콘텐츠 생성
  (요약/번역/태깅/관련기사 링크). 왜 특정 관련기사를 링크했는지, 요약이 원문 근거에
  기반했는지 추적·검증 어려움.
- 도입 시: 에이전트 추론 기록 도구 + 요약-원문 근거 자가검증. 검색과 독립적(에이전트 생성 측).

## 이미 보유 (추가 불필요)

하이브리드 검색 6단계 전체 / 임베딩 캐싱 / RRF·MMR·cosine threshold /
에이전트 도구 루프(`ArticleAgent` + 3 tools) / pgvector·neighbor / pg_search /
Solid Queue·Cache·Cable / Turbo(Hotwire)

## 재개 방법

이 문서를 읽고 **A의 미해결 설계 질문 6개부터** brainstorming으로 좁힌 뒤
`docs/superpowers/specs/`에 정식 design 작성 → writing-plans → 구현.
