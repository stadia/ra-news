# RA News 프로젝트 개발 히스토리

## 2025년 11월

### 2025-11-18
- **AI 제공자 확장**: OpenAI 지원 추가 및 기본 모델 설정 업데이트

### 2025-11-14
- **릴리스 정리**:
  - 원격 main 브랜치와 동기화

### 2025-11-12
- **검색 품질 개선**:
  - 기사 유사도 검색 방식을 코사인/기타 지표에서 **유클리드 거리 기반**으로 변경

### 2025-11-08
- **사이트 소프트 삭제 지원**:
  - `Site` 모델에 soft delete(discard) 도입 및 관련 잡 스코프 수정 (#374)
  - Madmin에서 Site에 대한 삭제/복구(discard/restore) 액션 추가
- **관리 UI 개선**: 사이트 삭제/복구 시 안내 문구 및 알림 메시지 개선
- **CI/운영 환경 정리**:
  - Gemini CLI 관련 GitHub 워크플로우 제거
  - 잠재 버그 탐지 및 수정 (#372)
- **데이터베이스 인덱스**:
  - 사이트/기사 관련 인덱스 추가 및 최적화

### 2025-11-03
- **프레임워크 업그레이드**:
  - Rails 8.1로 업그레이드 (#351)
  - 관련 코드 및 설정에서 발생하는 경고 처리(워닝 회피)
  - 기타 의존성 정리 및 설정값 업데이트

---

## 2025년 10월

### 2025-10-29
- **성능 및 안정성 개선**:
  - `Site.last_checked_at` 기본값을 **6개월 전**으로 설정하여 신규 사이트 초기 상태 명확화
  - 환경설정/Preference 캐싱 및 동적 접근자 리팩토링

### 2025-10-26
- **데이터베이스 청소**: 사용되지 않는 인덱스 제거로 불필요한 오버헤드 감소

### 2025-10-24
- **슬로우 쿼리 대응**:
  - 기사 정렬 및 조회에 필요한 인덱스 추가 (`articles.created_at` 포함)
  - 기존 인덱스 구조 재검토 및 최적화
  - 마이그레이션 스크립트 정리 및 재작성
- **개발 환경 개선**:
  - PostgreSQL 관련 MCP 설정 추가
  - 메일 설정 개선 및 `DEFAULT_IMAP_ADDRESS` 상수 도입

### 2025-10-22
- **URL 처리 강화**:
  - `mailto:` 링크를 링크 추출 로직에서 무시하도록 처리

### 2025-10-20
- **환경 변수 및 빌드 도구 정리**:
  - `ruby2_keywords` 제거
- **메일 설정 개선**:
  - 메일 환경 변수를 `MAIL_*` 네이밍으로 통일
  - IMAP 서버 주소 오버라이드 옵션 추가
- **유사 기사 검색 향상**:
  - `summary_body` 인덱싱 및 **확인(confirmed)** 된 아티클만 유사 기사 필터링에 사용하도록 변경

### 2025-10-19
- **테스트 환경 정리**:
  - Mocha 제거 및 Minitest 스텁으로 테스트 코드 마이그레이션
  - SQLite3 설정 공통화
- **정책 및 문서화**:
  - 에이전트/개발 지침 문서(AGENTS.md) 업데이트
  - `rbs_rails` 의존성 제거

### 2025-10-13
- **외부 연동 개선**:
  - 테스트용 ngrok 설정 추가
  - Slack OAuth 클라이언트 설정 추가
  - MCP 관련 설정 추가
- **CI 안정화**:
  - CI 테스트 설정 수정 및 빌드 신뢰성 개선
  - ignore_hosts fixture 추가
  - 테스트 환경에서 SQLite 데이터베이스 구성 및 JSON 컬럼 대응
- **캐시 및 인프라**:
  - Solid Cache 활성화 및 SQLite DB 설정
  - Preference 캐시 도입 및 docker-compose 설정 리팩토링

### 2025-10-11
- **소셜/메타 기능**:
  - 상단/푸터에 소셜 링크 추가
  - PWA manifest 활성화
  - Mastodon OAuth 엔드포인트를 ruby.social로 변경
  - Mastodon 클라이언트가 Preference 기반 동적 사이트 URL을 사용하도록 수정

### 2025-10-10
- **UI/로컬라이제이션**:
  - 뒤로가기 링크 텍스트를 한국어로 로컬라이즈
  - 폼 배경색을 흰색으로 설정해 가독성 개선
- **OAuth 구조 개선**:
  - OAuth 클라이언트 구성을 Preference 기반으로 통합 관리
  - SocialMediaService 기반 클래스 도입
  - OAuth URL을 상수(`OAUTH_CONFIG`)로 중앙화

### 2025-10-09
- **소셜 연동 리팩토링**:
  - Mastodon, X(Twitter) OAuth 통합 구조 정비
  - X OAuth 토큰 리프레시 처리 및 서비스 레이어 도입

### 2025-10-07
- **OAuth 및 설정 리팩토링**:
  - Preference 캐시 초기 구현 후 제거 및 구조 재조정
  - X 클라이언트 설정을 Preference 기반으로 변경
  - 소셜 OAuth 인증 로직을 서비스 객체/공통 모듈로 일반화
  - Preference 모델에 동적 accessor 추가
  - Madmin에서 Preference 파라미터 허용 로직 강화

### 2025-10-06
- **AI 설정 변경**:
  - AI 구성(모델/지침)을 Claude 중심에서 Gemini 중심으로 마이그레이션

---

## 2025년 9월

- **환경설정 및 요약 시스템 고도화**:
  - Preference 모델 및 캐시 구조 개선, IGNORE_HOSTS 설정을 환경설정으로 외부화
  - `summary_body` 컬럼 도입 및 요약 텍스트 추출/검색 파이프라인 정비
- **LLM/배치 처리 및 테스트 인프라 개선**:
  - LLM 기반 Article 배치 처리 로직 리팩토링
  - SQLite3 기반 테스트 환경 정리 및 CI 워크플로우 안정화
- **소셜 포스팅 기능 확장**:
  - Article 소셜 포스팅 여부 추적 필드 추가 및 Twitter 포스팅 로직을 서비스 객체로 분리

## 2025년 8월

- **타입/서비스 레이어 및 에이전트 정비**:
  - Steep 및 rbs_rails 도입으로 타입 체킹 강화
  - `ApplicationService`, `SitemapService` 등 서비스 레이어 도입
  - 에이전트/프롬프트 구조 전반 리팩토링 및 Dashboard 1차 구현
- **UI/UX 및 컴포넌트화**:
  - view_component 기반 Article UI 도입 및 불필요한 스타일/스크립트 정리
  - 디자인 원칙 문서화 및 네비게이션/레이아웃 개선
- **소셜/워크플로우/CI 개선**:
  - Ruby 기사 자동 X/Twitter 포스팅, 태그 포함 전략 개선
  - GitHub Actions, Gemini/Claude 워크플로우 및 triage 자동화 정비
  - RSS/Gmail 처리 및 페이지네이션 동작 개선

## 2025년 7월

- **검색 및 추천 기능 고도화**:
  - pg_search 설정을 한국어/영어 사전으로 보강하고 multisearchable 대상에 `body` 필드를 추가
  - tsearch 사전을 "simple"에서 "korean"으로 전환해 한국어 검색 품질 향상
  - 관련 기사 섹션 및 임베딩 기반 추천 품질을 전체적으로 개선
- **UI/UX 및 내비게이션 개선**:
  - 기사 인덱스/상세 뷰에 새로운 헤더와 스크롤 애니메이션 추가
  - 네비게이션 메뉴 토글, 페이지 로더, 스크롤 애니메이션 등 상호작용 요소를 보강
  - 댓글 섹션 구조/스타일 및 글자 수 카운터, 한국어 시간 표시 등 사용자 경험 전반 개선
  - SEO 및 Open Graph 메타 태그 추가
- **플랫폼 및 도메인 정비**:
  - 서비스 도메인을 `ruby-news.kr`로 전환하고 리다이렉트 처리 도입
  - IGNORE_HOSTS 및 URL 처리 로직을 다듬어 크롤링 품질을 향상
- **품질/에이전트/로깅**:
  - Article 라이프사이클 및 로깅 구조를 정리하고, 에이전트/코드 리뷰 워크플로우 문서를 정리
  - RSS 피드 추가, 캐시·라우팅 정책 정비 등 운영 편의성과 가시성을 강화

## 2025년 6월

- **검색/DB 기능 확장**:
  - pg_search 및 pg_bigm 기반 전문 검색 도입
  - 한국어 텍스트 검색 및 vector embedding 컬럼 추가로 검색·추천 기능 강화
- **댓글·태그·피드 처리 고도화**:
  - 중첩 댓글 시스템 구현 및 Hacker News/RSS 클라이언트 개선
  - URL 필터링·검증·중복 방지 로직 정비
- **관리·스케줄링 및 브랜딩**:
  - Madmin 관리 대시보드 추가와 잡 스케줄링 구조 개선
  - 프로젝트 이름을 ra-news로 변경하고 사이트 관리/메타데이터 추출 로직 정리

## 2025년 5월

- **핵심 기능 구축**:
  - Article/Users CRUD, 관리자 기능, 인증·세션·비밀번호 리셋 흐름 정비
  - Gmail 기반 기사 수집, RSS 작업, YouTube 자막 처리 등 자동 수집 파이프라인 구현
- **UI/UX 및 프론트엔드 기반**:
  - Tailwind CSS, 카드형 기사 목록, 검색 헤더, Markdown 렌더링, 페이지네이션 도입
  - 한국어 로케일, 레이아웃 리팩토링, 기본 스타일/레이아웃 정착
- **품질/배포 인프라**:
  - RBS 타입 시스템 도입, 초기 테스트/CI/CD(Docker, GitHub Actions) 구성
  - Honeybadger, Google Analytics, Docker/traefik 설정으로 운영 환경 준비

## 2025년 4월

- **프로젝트 초기화**:
  - 기본 Rails 프로젝트 구조 생성 및 Steep/Sorbet 타입 시스템 설정
  - Articles/Users 리소스, 인증·비밀번호 리셋, Chat/Message/ToolCall 등 초기 기능과 라우팅 구성

---

## 주요 기술 스택 및 특징

### 백엔드
- **Ruby on Rails 8.x**: 메인 프레임워크
- **PostgreSQL**: 데이터베이스 (pg_search, vector embedding 지원)

### 프론트엔드
- **Hotwire (Turbo + Stimulus)**: SPA-like 사용자 경험
- **Tailwind CSS**: 현대적이고 반응형 UI
- **Kramdown**: Markdown 렌더링

### AI 및 자동화
- **RubyLLM / OpenAI / Gemini**: AI 기반 콘텐츠 생성 및 요약
- **YouTube API**: 동영상 자막 추출
- **RSS 피드 처리**: 자동화된 콘텐츠 수집

### 개발 도구
- **Sorbet + RBS + Steep**: 정적 타입 검사
- **RuboCop**: 코드 스타일 관리
- **GitHub Actions**: CI/CD 파이프라인
- **Docker**: 컨테이너화
- **Madmin**: 관리자 대시보드

### 주요 기능
1. **다국어 지원**: 한국어/영어 콘텐츠 처리
2. **전문 검색**: PostgreSQL 기반 고급 검색
3. **댓글 시스템**: 댓글 지원
4. **태그 시스템**: 콘텐츠 분류 및 관리
5. **자동화된 콘텐츠 수집**: RSS, Gmail, Hacker News, YouTube
6. **Vector Embedding**: 유사 기사 추천 및 유사도 검색
7. **SEO 최적화**: 메타 태그 및 사이트맵 자동 생성
