# Ruby-News 프로젝트 개발 히스토리

## 2026년 2월

- **Phlex/RubyUI 기반 UI 전환 가속**:
  - ERB 뷰를 Phlex 컴포넌트로 본격 전환하고, 댓글/기사/사용자 화면을 재구성
  - RubyUI `Button`, `Link`, `Card`, Typography 컴포넌트를 도입해 화면 일관성 강화
  - PhlexIcons, 메타 태그, 대화상자/페이지네이션 컴포넌트 적용으로 UI 기반 정비
- **기사 처리·댓글·운영 기능 개선**:
  - AI 에이전트 기반 요약/번역 파이프라인을 `ArticleAgentsService`, `one_shot_agent` 중심으로 재정리
  - 기사 생성 경쟁 상태 처리, 중복 감지 강화, 요약 길이 기준 조정, 배치 처리 오류 대응
  - 비회원 댓글 비밀번호 인증, 최근 댓글 사이드바, 댓글 수 표시 등 커뮤니티 기능 확장
- **스크래핑/문서/개발 환경 확장**:
  - `ruby-mcp-client`와 MCP 기반 HTML fetch 지원 추가 및 스크래핑 문서 보강
  - GitHub URL용 README 추출, Scrapling/Chrome 서비스, web push VAPID 환경 변수 추가
  - `ruby_llm-agents` 제거 후 `ruby_llm` 중심으로 정리하고 의존성 전반 업데이트

## 2026년 1월

- **PostgreSQL 기준 테스트·CI 체계 강화**:
  - 테스트 환경에서 PostgreSQL 확장과 vector embedding을 활성화하고, DB 생성/마이그레이션 흐름 정비
  - PostgreSQL 서비스용 Docker 이미지와 GitHub Container Registry 인증을 추가해 CI 재현성 개선
  - 시스템 테스트 워크플로우와 관련 문서를 보강해 실제 운영 전제와 가까운 검증 체계를 마련
- **서비스 계층·소셜 연동 리팩토링**:
  - `ContentService`, `SocialMediaService`를 Dry::Operation 패턴으로 재구성하고 서비스 레이어 테스트 확장
  - 소셜 게시물 삭제와 `social_post_ids` 추적을 추가하고 Mastodon 응답 파싱 안정성 개선
  - Article slug 생성, Site 동작, YouTube 자막 예외 처리 등 핵심 도메인 안정성 보완
- **보안·의존성·운영 설정 정비**:
  - `bundler-audit`, `minitest`, `minitest-mock`, `youtube-transcript-rb` 등 개발·검증 도구를 도입
  - Rails 8.1 기준 설정과 RuboCop 구성을 갱신하고 DB 커넥션 풀 기본값을 조정
  - 의존성 업데이트와 Rails 감사 리포트 추가로 유지보수 기준을 정리

## 2025년 12월

- **런타임·데이터베이스 업그레이드**:
  - Ruby 4.0 업그레이드를 진행하고 관련 gem 의존성을 조정
  - PostgreSQL 17로 업그레이드하고 Dockerfile/CMD/포트 노출 설정을 함께 정비
- **UI 컴포넌트·스타일 체계 조정**:
  - `shadcn-rails`, Heroicon, ViewComponent를 활용해 로그인 요구 UI와 아이콘 처리 방식을 재구성
  - Tailwind 구식 유틸리티를 최신 명칭으로 교체하고 비로그인 댓글 렌더링을 개선
- **검색·권한·운영 워크플로우 개선**:
  - 검색 인덱스 재생성을 잡 클래스로 이동하고 기본 기사 조회에서 related scope를 제거
  - 사용자 role 설명, `Current` 참조 정리, JavaScript 지원 추가 등 애플리케이션 동작을 다듬음
  - 로컬 PostgreSQL Docker 실행 환경과 Claude PR Assistant 워크플로우를 추가해 개발 흐름 보강

## 2025년 11월

- **프레임워크·AI 설정 정비**:
  - Rails 8.1로 업그레이드하고 관련 경고와 설정값을 정리
  - OpenAI 지원과 기본 모델 설정을 추가해 AI 제공자 구성을 확장
- **검색·데이터 모델 개선**:
  - 기사 유사도 검색을 유클리드 거리 기반으로 변경해 검색 품질을 조정
  - 사이트/기사 관련 인덱스를 추가·최적화해 조회 성능을 보강
  - `Site` 모델에 soft delete(discard)를 도입하고 관련 잡 스코프를 정비
- **관리 UI·운영 워크플로우 정리**:
  - Madmin에 Site 삭제/복구 액션을 추가하고 안내 문구와 알림 메시지를 개선
  - Gemini CLI 관련 GitHub 워크플로우를 제거하고 릴리스 브랜치 정리를 진행
  - 잠재 버그 수정과 운영 설정 정리로 배포 안정성을 높임

---

## 2025년 10월

- **소셜 OAuth·환경설정 구조 재정비**:
  - Mastodon, X(Twitter) OAuth 흐름을 서비스 객체 중심으로 통합하고 토큰 처리 구조를 개선
  - Preference 기반 동적 설정, 동적 accessor, 파라미터 허용 로직을 정비해 환경설정 관리 일관성 확보
  - AI 기본 구성을 Claude 중심에서 Gemini 중심으로 옮기고 메일 환경 변수 체계도 `MAIL_*` 기준으로 정리
- **검색·성능·데이터베이스 최적화**:
  - `summary_body` 인덱싱과 confirmed 기사 필터링으로 유사 기사 검색 정확도를 높임
  - 기사 정렬/조회용 인덱스를 추가하고 사용되지 않는 인덱스를 제거해 슬로우 쿼리를 완화
  - `Site.last_checked_at` 기본값 조정, URL 추출 시 `mailto:` 제외 등 수집 안정성을 다듬음
- **외부 연동·개발 환경·문서 정비**:
  - Slack OAuth, ngrok, PostgreSQL MCP 등 외부 연동과 로컬 개발 설정을 보강
  - CI 테스트 설정, 캐시 구성, docker-compose를 정리해 개발·검증 환경을 안정화
  - AGENTS.md 업데이트, `rbs_rails` 제거, PWA/소셜 링크 추가 등 운영·문서·UI 기반을 함께 손봄

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
