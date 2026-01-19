[![CI](https://github.com/stadia/ra-news/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/stadia/ra-news/actions/workflows/ci.yml)

# Ruby-News (RA News)

Ruby-News는 **한국어로 Ruby/Rails 관련 뉴스를 모아 보여주는 AI 기반 뉴스 허브**입니다.  
RSS, 이메일 뉴스레터, YouTube, Hacker News 등 다양한 소스를 수집하고, AI로 한국어 요약과 메타데이터를 생성해 제공합니다.

> 이 문서는 **공개 저장소용 소개 + 로컬 개발/기여 가이드** 역할을 모두 수행합니다.

---

## 주요 기능

- **콘텐츠 수집**
  - RSS 피드 (블로그, 뉴스레터)
  - 이메일 뉴스레터(Gmail)
  - YouTube 동영상(자막 기반)
  - Hacker News 스토리
- **AI 요약 및 메타데이터 생성**
  - Gemini 기반 한국어 요약
  - 기사 메타데이터(태그, 카테고리, 관련도 등) 자동 생성
  - 벡터 임베딩을 이용한 유사 기사 추천
- **검색 및 추천**
  - PostgreSQL 한국어/영어 전문 검색(tsvector)
  - `pgvector` 기반 유사도 검색(벡터 거리)
- **사용자 경험**
  - Hotwire(Turbo/Stimulus) 기반 SPA-like 탐색
  - Tailwind CSS 4.2 기반 반응형 UI
  - 중첩 댓글(쓰레드) 시스템
  - 태그 기반 필터링 및 탐색
- **관리/운영**
  - Madmin 기반 관리자 대시보드
  - Solid Queue/Cache/Cable을 사용하는 Rails 8 백그라운드 작업 및 실시간 기능
  - Honeybadger, GitHub Actions, Docker를 통한 모니터링/CI/CD

---

## 기술 스택

### 백엔드

- **Ruby 4.0**
- **Rails 8** (Solid Queue / Solid Cache / Solid Cable)
- **PostgreSQL**
  - 한국어/영어 tsvector 기반 전문 검색
  - `pgvector` 확장(1536차원 임베딩 컬럼)
- **Job & 스케줄링**
  - Solid Queue 기반 백그라운드 잡
  - Rails 스케줄링(예: RSS, Gmail, YouTube, HN 주기 실행)

### AI & 임베딩

- **RubyLLM**
  - Gemini 모델을 사용해 한국어 요약 및 메타데이터 생성
- **요약/임베딩 파이프라인**
  - `ArticleJob`을 중심으로 한 비동기 처리
  - 벡터 임베딩을 사용한 기사 유사도 검색 및 추천

### 프론트엔드

- **Hotwire (Turbo + Stimulus)**
- **Tailwind CSS 4.2**
  - 공통 토큰: `app/assets/stylesheets/tokens.css`
- **Kramdown**: Markdown 렌더링

### 품질 & 보안

- **Steep + RBS + RBS 인라인 주석**: 타입 검증
- **RuboCop**: 코드 스타일 및 정적 분석
- **Brakeman**: 보안 스캐닝
- **GitHub Actions**: CI (테스트, 린트, 타입체크)

---

## 도메인 모델 개요

- **Article**
  - 주요 콘텐츠 모델
  - 필드: 제목, 본문, 요약, 벡터 임베딩, slug, is_related, is_posted 등
  - 기능:
    - AI 기반 요약/메타데이터
    - 벡터 임베딩을 이용한 유사 기사 검색
    - soft delete(discard) 지원
- **Site**
  - RSS/뉴스레터/YouTube/HN 등 외부 소스
  - `kind`/`client` enum으로 소스 유형 구분
  - 마지막 체크 시간, 오류 상태 등 관리용 메타데이터
- **Comment**
  - awesome_nested_set 기반 **중첩 댓글** 구조
  - 깊이 제한(`Comment::MAX_DEPTH`)으로 트리 폭 관리
- **User**
  - 커스텀 인증 시스템(Devise 미사용)
  - 세션 토큰 관리, 관리자 여부(`admin?`) 등

---

## 주요 배치 잡(Background Jobs)

핵심 처리 로직은 모두 백그라운드 잡으로 동작합니다.

- **ArticleJob**
  - 기사 본문을 AI로 분석해
    - 한국어 요약
    - 메타데이터(요약 본문, 태그, 관련도 플래그 등)
    - 벡터 임베딩
    를 생성합니다.
- **RssSiteJob**
  - RSS 피드를 주기적으로 크롤링
  - 신규/갱신 기사 생성 및 ArticleJob enqueue
- **YoutubeSiteJob**
  - YouTube 동영상 메타데이터 및 자막 추출
  - 기사 생성 및 요약/임베딩 처리
- **GmailArticleJob**
  - 이메일 뉴스레터(Gmail)에서 링크 추출
  - 관련 기사 생성 및 처리

> 모든 Job은 Honeybadger 보고 및 재시도 정책을 고려하여 작성되어 있습니다.

---

## 검색 & 추천 시스템

### 전문 검색

- PostgreSQL tsvector + GIN 인덱스 사용
- 한국어/영어 사전(dictionaries) 동시 지원
- 제목/본문 통합 검색 및 필터링

### 벡터 기반 유사도 검색

- `pgvector` 확장
- 기사당 1536차원 임베딩 컬럼
- 특정 기사와 **유사한 기사 목록**을 거리 기반(예: 유클리드)으로 조회

---

## 실행 방법

### 1. 요구 사항

- Ruby 4.0
- PostgreSQL 14+ with 확장:
  - pg_bigm (바이그램 전문 검색)
  - textsearch_ko (한국어 형태소 분석)
  - pgvector (벡터 임베딩)
- Node.js (Tailwind 빌드용)
- Redis (옵션: 캐시/백그라운드 처리 구성에 따라)

> **macOS 사용자**: PostgreSQL 확장 설치 방법은 [PostgreSQL 확장 설치 가이드](docs/postgresql-extensions.md)를 참고하세요.

### 2. 의존성 설치

```bash
bundle install
bin/rails db:setup  # db:create + db:schema:load + seed
bin/rails db:migrate
```

> pgvector 확장이 활성화되어 있어야 합니다.  
> 로컬에서 필요한 경우 `CREATE EXTENSION IF NOT EXISTS vector;` 를 직접 실행하거나, 마이그레이션을 확인해 주세요.

### 3. 애플리케이션 실행

```bash
bin/dev                      # Rails + CSS watcher (Procfile.dev)
# 또는
bin/rails server             # 웹 서버만
bin/rails tailwindcss:watch  # CSS watch만 별도 실행
```

### 4. 백그라운드 잡 실행

```bash
bin/jobs                     # Solid Queue worker 실행
# 또는
bin/rails jobs:work
bin/rails jobs:stats         # 큐 상태 확인
```

---

## 테스트 & 품질 도구

```bash
bin/rails test                                  # 전체 테스트
bin/rails test:system BROWSER=headless_firefox  # 시스템 테스트(headless)
bin/rubocop                                     # 스타일/린트
bundle exec steep check                         # Steep 타입 체크
bin/brakeman                                    # 보안 점검
```

CI 파이프라인은 위 명령들을 기준으로 구성되어 있습니다.

---

## 환경 설정

민감한 설정값(API 키, 토큰 등)은 **소스에 직접 커밋하지 않습니다.**

- Rails credentials
  - `config/credentials.yml.enc`에 AI 키(Gemini/OpenAI 등), 외부 API 자격증명 저장
- `.env` / 환경 변수
  - 로컬 개발에서는 `.env`를 사용해 DB, 메일, 외부 서비스 설정
- 메일/Gmail/YouTube/HN
  - 각 클라이언트 별로 필요한 API 키/토큰/계정 정보를 환경 변수로 설정

---

## 개발자용 구조 가이드

### 인증 패턴

- Devise 미사용, 커스텀 세션 기반 인증
- `Current.user`를 통해 요청 컨텍스트에서 현재 사용자 관리
- 일부 컨트롤러는 `allow_unauthenticated_access`로 비로그인 접근 허용

### 소프트 삭제(Soft Delete)

- `discard`를 사용한 soft delete
- 기본 조회에서는 `kept` scope를 사용
- 관리자 화면에서 삭제/복원(discard/restore) 가능

### AI/Tool 통합

- RubyLLM 기반 Tool 패턴 사용
- 예: `ArticleBodyTool` — 본문 추출/전처리용 툴
- 신규 Tool 추가 시:
  - 대응하는 설정 파일 등록
  - QA 환경에서 feature flag로 점진적 적용 권장

### 타입 & 에러 처리

- 모델/서비스에 RBS 인라인 주석을 점진적으로 도입
- Steep를 사용해 서비스/도메인 레이어 시그니처를 검증
- ApplicationJob, 클라이언트 레이어에서
  - 외부 API 에러를 공통 포맷으로 감싸고
  - Honeybadger로 보고하는 패턴 사용

---

## 로컬에서 해볼 수 있는 것들

1. **DB seed 후 서버 실행**
   - 기본 기사/사이트/사용자 데이터가 포함되어 있으면
   - 검색, 태그, 댓글 기능을 직접 확인할 수 있습니다.
2. **RSS/Gmail/YouTube Job 수동 실행**
   - 특정 Site에 대해 `RssSiteJob.perform_later(site.id)` 등의 방식으로 수동 트리거
3. **AI 파이프라인 테스트**
   - Article을 하나 생성하고 `ArticleJob.perform_later(article.id)`로 요약/임베딩 처리 확인

---

## 기여 방법

1. 이슈를 등록하거나 기존 이슈를 선택합니다.
2. 새 브랜치를 생성합니다.
3. 변경 사항을 구현하고 **테스트 + 린트 + 타입 체크**를 통과시킵니다.
4. PR 설명에 다음을 꼭 포함해 주세요.
   - 변경 목적/배경
   - 사용자 영향(특히 검색/큐/캐시/인덱스에 영향이 있을 경우)
   - 롤백 계획 또는 플래그 전략
5. 리뷰 코멘트에 따라 수정 후 머지합니다.

> 이 저장소는 한국어 중심의 프로젝트이므로, PR 설명과 커밋 메시지도 가능하면 한국어로 작성해 주세요.  
> 로그/에러/명령어 출력 등은 원문(영어) 그대로 유지해도 됩니다.

---

## 라이선스

라이선스 정보가 확정되지 않았다면 Maintainer에게 문의하거나 이 섹션을 갱신해 주세요.  
(예: MIT, Apache 2.0 등)

---

## 문의

- 버그/기능 제안: GitHub Issues
- 보안 관련 문의: 공개 이슈 대신 Maintainer에게 직접 연락하는 것을 권장합니다.

Ruby-News를 사용해 주셔서 감사합니다.  
한국어 Ruby/Rails 커뮤니티에 도움이 되는 뉴스 허브가 되도록 계속 개선해 나가고 있습니다.
