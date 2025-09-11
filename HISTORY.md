# RA News 프로젝트 개발 히스토리

## 2025년 7월

### 2025-07-05
- **pg_search 개선**: 제목 및 본문에 대한 한국어 및 영어 tsearch 사전 설정 추가
- **의존성 업데이트**: faraday 버전을 2.13.1에서 2.13.2로 업데이트
- **검색 성능 개선**: pg_search 초기화에서 tsearch 사전 설정을 "simple"에서 "korean"으로 변경

### 2025-07-04
- **검색 성능 최적화**: PgSearch::Multisearch.rebuild 호출 시 clean_up 및 transactional 옵션 최적화
- **사용자 경험 대폭 개선**:
  - 한국어 시간 표시 헬퍼 메서드 구현
  - 반응형 이미지 태그 헬퍼 추가
  - 스마트 텍스트 절단 메서드 추가
  - 네비게이션 메뉴 토글 및 애니메이션 기능
  - 페이지 로더 컨트롤러로 Turbo 네비게이션 중 로딩 상태 관리
  - 스크롤 시 요소 애니메이션 기능 구현
- **UI/UX 개선**:
  - 기사 인덱스 뷰에 새로운 헤더 및 스크롤 애니메이션 추가
  - 기사 상세 뷰 레이아웃 및 메타데이터 표시 개선
  - 댓글 섹션 스타일링 및 오류 처리 향상
  - 댓글 폼에 글자 수 카운트 기능 추가
  - SEO 및 Open Graph 메타 태그 추가
- **관련 기사 기능**: 유사 기사 섹션 추가 및 nil 체크로 안전성 개선

### 2025-07-03
- **호스트 필터링**: Article 모델의 IGNORE_HOSTS에 localhost 추가

### 2025-07-02
- **YouTube 처리 개선**: LinkHelper에서 youtube_id 메서드 추가 및 URL에서 YouTube ID 안전 추출
- **의존성 업데이트**: faker 버전을 3.5.1에서 3.5.2로 업데이트
- **작업 성능 조정**: HackerNewsSiteJob 및 YoutubeSiteJob에서 기사 생성 후 1초 대기 추가
- **검색 기능 강화**: Article 모델의 multisearchable에 body 필드 추가

### 2025-07-01
- **Article 모델 개선**: YouTube ID 추출, URL 처리, 기사 검색 로직 개선

## 2025년 6월

### 2025-06-30
- **스케줄링 조정**: hacker_news_job 스케줄 조정
- **의존성 업데이트**: madmin 및 selenium-webdriver 버전 업데이트
- **피드 처리 개선**: RssSitePageJob 피드 처리 간소화 및 로깅 향상

### 2025-06-27
- **URL 검증 개선**:
  - Article 모델에 URL 무시 로직 추가
  - 서브도메인 매칭 로직 추가
  - 중복된 호스트 제거 및 URL 검증 통합
- **중복 방지**: RssSitePageJob에서 중복 아티클 확인 로직 개선
- **오류 처리**: ActiveRecord::RecordInvalid를 ActiveRecord::ActiveRecordError로 수정

### 2025-06-26
- **작업 안정성 개선**: Gmail 및 RSS 작업에서 재시도 로직 추가
- **링크 처리 기능 확장**:
  - RssClient에 리다이렉션 처리 로직 추가
  - LinkHelper 및 RssHelper 모듈 생성
  - Site 모델에 rss_page enum 추가
- **의존성 업데이트**: sorbet 버전 업데이트 (0.5.12200 → 0.5.12203)

### 2025-06-25
- **관리 대시보드 개선**:
  - Madmin 레이아웃 및 뷰 파일 대폭 개선
  - 검색 필드, 버튼 스타일 업데이트
  - 폼 요소 및 내비게이션 개선
  - HTML 구조 수정 및 사용자 경험 향상
- **작업 스케줄링 개선**:
  - enqueue_all 메서드 단순화
  - 작업 대기 로직 개선
  - recurring.yml 업데이트
- **다국어 지원**: 언어 설정 추가 및 제목을 "RA || 루비 AI 뉴스"로 변경
- **데이터베이스 개선**: vector 확장 기능 활성화 및 embedding 컬럼 추가

### 2025-06-24
- **URL 필터링 강화**:
  - IGNORE_HOSTS에 reddit.com, mail.beehiiv.com, rubygems.org, javascriptweekly.com 추가
  - URL 처리 로직 개선 및 쿼리 매개변수 제외 로직 추가
- **작업 성능 조정**: ActiveJob 작업 대기 시간을 1분으로 조정
- **검색 개선**: slug이 없는 기사 제외하여 검색 정확도 향상
- **오류 처리**: 중복 기사 생성 오류 로깅 추가

### 2025-06-23
- **개발 환경 정리**: tapioca gem 제거 및 sorbet 설정 파일 수정
- **한국어 검색 지원**: tsvector 컬럼에 한국어 설치 및 한국어 텍스트 검색 기능 구현
- **콘텐츠 처리 강화**:
  - body 컬럼을 articles에 추가
  - ArticleBodyTool로 콘텐츠 추출 기능 구현
  - vector embedding 지원 추가

### 2025-06-20
- **링크 처리 확장**: LibHunt 및 Ruby Weekly URL 링크 추출 기능 추가
- **사용자 경험 개선**:
  - 기사 조회 시 slug와 id 모두 지원
  - Google Fonts import를 body 끝으로 이동
- **Gmail 처리 개선**: Gmail 삭제 로직 추가 및 slug 생성 개선
- **의존성 업데이트**: 여러 gem 업데이트 및 ArticleResource에 필드 추가

### 2025-06-18
- **AI 모델 조정**: ArticleJob에서 RubyLLM.chat 메서드에 온도 설정 추가

### 2025-06-14
- **사용자 권한**: User 모델에 admin? 메서드 추가
- **URL 처리**: Article 모델에 slug를 사용한 URL 설정 및 검색 메서드 추가
- **댓글 관리**: CommentsController 및 CommentResource 생성

### 2025-06-13
- **요청 헤더 개선**: Faraday 요청에 User-Agent 헤더 추가
- **YouTube 메타데이터**: URL 생성 방식을 youtube_id 사용으로 수정

### 2025-06-12
- **컨트롤러 정리**: ArticlesController에서 불필요한 액션 제거
- **정렬 개선**: 홈 컨트롤러에서 기사를 게시일 기준 내림차순 정렬

### 2025-06-11
- **댓글 시스템 구현**:
  - awesome_nested_set gem 추가
  - 중첩 댓글 지원
  - 댓글 모델, 컨트롤러, 뷰, 테스트 완성
- **개발 환경**: CI 배지 추가 및 JSON 파싱 오류 처리 개선
- **연관관계**: site 및 article 연관관계 추가

### 2025-06-10-11
- **프로젝트 이름 변경**: al-news에서 ra-news로 변경
- **Ruby 버전 업데이트**: 3.4.3에서 3.4.4로 업데이트
- **테스트 추가**: Article 및 Site 모델 검증 및 스코프 테스트
- **사이트 관리 개선**: client enum 처리 및 last_checked_at 타임스탬프 관리

### 2025-06-09
- **메타데이터 추출 개선**: 기사 메타데이터 추출 및 사이트 체크 타임스탬프 업데이트
- **RSS 파싱 개선**: published_at 필드 우선순위 처리 및 URL 처리 간소화
- **테스트 정리**: 사용되지 않는 시스템 테스트 및 모델 테스트 파일 제거
- **AI 모델 업데이트**: chat 모델을 "gemini-2.5-flash-preview-05-20"으로 업데이트

### 2025-06-08
- **관련성 기반 처리**: is_related 필드 추가 및 관련성에 따른 기사 삭제 로직
- **Hacker News 개선**: 태그의 taggings_count 조건 조정 (4→2)
- **피드 처리 로직**: RSS 및 HackerNews 클라이언트 개선

### 2025-06-06
- **Hacker News API 통합**:
  - HackerNews 클라이언트 및 작업 추가
  - 새로운 스토리 및 태그 처리
  - 주기적 작업 스케줄 설정
- **태그 시스템**: is_confirmed 필드 추가 및 TagResource 인덱스 추가
- **삭제 처리**: discard gem 추가 및 soft delete 구현

### 2025-06-05-06
- **의존성 관리**: RuboCop 1.76.0 업데이트 및 여러 gem 버전 업데이트
- **Madmin 통합**: 관리 대시보드 추가 (#24)

### 2025-06-04
- **의존성 업데이트**: ruby_llm 버전을 "~> 1.3.0"으로 변경

### 2025-06-03
- **전문 검색 기능**:
  - pg_search 추가 및 PostgreSQL 확장 기능 설치
  - 제목 및 내용에 대한 GIN 인덱스 추가
  - tsvector 컬럼 및 인덱스 최적화
  - 검색 기능 구현 (#35)
- **데이터베이스 설정**: 데이터베이스 이름을 'ra-news'로 수정

### 2025-06-01
- **PostgreSQL 확장**: pg_bigm 확장 추가 (pg_trgm 대체)

### 2025-05-30
- **YouTube 기능 확장**:
  - is_youtube 필드 추가
  - 메타데이터 생성 로직 개선
  - YouTube 관련 필드 추가
- **UI 개선**: body 스타일 및 입력 요소 텍스트 색상 적용
- **AI 모델**: ruby_llm 업데이트 및 LLM 모델/지침 수정

### 2025-05-29
- **의존성 정리**: rubocop 및 sorbet 버전 업데이트

### 2025-05-28-29
- **YouTube 처리 개선**:
  - 비디오 정보 기반 슬러그 및 게시 날짜 설정
  - 자막 추출 로직 개선 및 다국어 캡션 지원
  - get 메서드 다국어 지원 구조 개선
- **코드 정리**: 중복 코드 제거 및 메서드 구조 개선

### 2025-05-27
- **슬러그 시스템**: 인덱스 변경 및 슬러그 업데이트 메서드 추가
- **버그 수정**: GmailArticleJob 변수 접근 수정

### 2025-05-26
- **관리 기능**:
  - AdminController 추가
  - 사용자 인증 개선
  - 코드 성능 향상
- **유효성 검사**: slug 필드 검증 개선

## 2025년 5월

### 2025-05-24
- **정렬 및 로케일**:
  - 기사 목록 정렬 기준 통일
  - 한국어 로케일 추가
  - 페이지 제목 통일
- **CI 환경**: self-hosted 환경 설정 테스트

### 2025-05-23
- **스타일 및 레이아웃**:
  - 아티클 페이지 색상 및 배경 조정
  - 최대 너비 설정 및 불필요한 요소 제거
- **태그 시스템**: acts_as_taggable_on gem 추가 및 태그 기능 구현
- **의존성**: rails-i18n gem 추가 및 Pagy 설정
- **로직 개선**: RSS 및 Gmail 작업 로직 향상

### 2025-05-22
- **UI 개선**:
  - 네비게이션 및 푸터 색상 변경
  - 홈 페이지 및 아티클 목록 페이지 추가
  - 스타일 및 레이아웃 대폭 개선
- **페이지네이션**: Pagy 통합으로 페이지네이션 추가

### 2025-05-21
- **AI 지침 개선**:
  - ArticleJob 한국어 출력 요구사항 추가
  - 정중한 톤 및 구조 지침 업데이트
  - summary_detail 글자 수 제한 및 로깅 형식 개선
- **애플리케이션 레이아웃**: 명확성과 일관성을 위한 리팩토링

### 2025-05-20
- **Tailwind CSS 통합**:
  - tailwindcss-rails gem 추가
  - 폰트 변수 추가
- **사이트맵**: SitemapJob 추가 및 삭제되지 않은 기사만 처리

### 2025-05-19
- **사용자 관리 기능**:
  - UsersController, 뷰, 라우트 설정
  - 사용자 생성, 수정, 삭제 기능
  - 세션 관리 개선
- **RSS 처리**: RailsAtScaleJob을 RssSiteJob으로 이름 변경 및 기능 개선
- **콘텐츠 추출**: ruby-readability gem으로 본문 추출 개선

### 2025-05-17
- **Markdown 지원**:
  - Kramdown을 사용한 본문 렌더링
  - slug 필드 추가 및 관련 마이그레이션
- **YouTube 처리**: URL 처리 개선
- **스케줄링**: gmail_article_job 스케줄 조정

### 2025-05-16
- **기사 CRUD**: 새로운 기사 작성 기능 및 CRUD 테스트 케이스
- **개발 지침**: GitHub Copilot 지침 문서 추가
- **의존성 정리**: 불필요한 gem 주석 처리

### 2025-05-14
- **이메일 처리**:
  - Gmail 클라이언트 및 GmailArticleJob 추가
  - 이메일 링크 추출 및 처리
- **데이터베이스**:
  - sites에 email 컬럼, articles에 deleted_at 컬럼 추가
  - origin_url, host, site_id 컬럼 추가
- **URL 처리**: 리다이렉션 상태 확인 및 디버그 로깅

### 2025-05-13
- **Gmail 통합**: Gmail 클라이언트 클래스 및 이메일 링크 추출 기능

### 2025-05-12
- **스타일링**: Tailwind CSS 색상 변수 및 HTML 구조 개선
- **HTTP 처리**: Faraday 사용 및 응답 상태 코드 오류 처리
- **스케줄링**: RailsAtScaleJob 스케줄 설정
- **테스트**: Site 모델 초기 fixture 및 테스트
- **배포**:
  - 허니배저 배포 알림 및 API 키 설정
  - Google Analytics 스크립트 추가
  - URL 유효성 검사 및 고유 인덱스 설정

### 2025-05-11
- **배포 환경**:
  - Docker 이미지 메타데이터 및 태그 설정
  - traefik 설정 추가
  - 데이터베이스 URL 수정
- **의존성**: ostruct 추가 및 autoload_lib 설정

### 2025-05-10-11
- **YouTube 기능**: YouTube 자막 기능 추가 및 ArticleJob 자막 처리
- **Faraday**: 요청 방식 개선
- **배포**: GitHub Actions 및 docker-compose.yml 설정

### 2025-05-09-10
- **코드 구조**: 가독성 및 유지보수성 향상을 위한 리팩토링

### 2025-05-08
- **CI/CD**:
  - Dockerfile에 node-gyp 및 python-is-python3 추가
  - Node.js 버전 22로 변경
  - 테스트 환경 개선
- **사용자 기능**: 사용자 및 비밀번호 관련 기능 정리
- **모델 정리**: Message, ToolCall, Chat 모델 삭제
- **비밀번호 리셋**: 비밀번호 리셋 기능 및 관리자 계정 추가

### 2025-05-07
- **UI/UX 대폭 개선**:
  - 기사 카드 레이아웃 개선
  - 헤더 및 검색 기능 추가
  - 기사 요약 및 상세 내용 JSON 형태 출력

### 2025-05-06
- **환경 설정**:
  - dotenv-rails 및 honeybadger 추가
  - 환경 변수 사용으로 개선
  - 라우트 루트 경로를 articles#index로 변경
- **CI/CD**: GitHub Actions 설정 및 Docker 빌드/푸시 구성

### 2025-05-02
- **RBS 타입 시스템**:
  - RBS 인라인 주석 추가
  - RBS 파일 생성 및 관리
  - Pagy gem RBI 정의
- **기사 표시**: 정렬된 기사 목록 및 상세 정보 표시 개선

### 2025-05-01
- **기사 시스템**:
  - Article 모델에서 사용자 참조를 선택적으로 변경
  - ArticleTool 클래스로 JSON 형태 Article 출력
  - 코드 구조 리팩토링
- **의존성**: 여러 gem 버전 업데이트

### 2025-04-28
- **프로젝트 초기화**:
  - 기본 프로젝트 구조 생성
  - Steep 및 Sorbet 타입 시스템 추가
  - 사용자 인증 및 비밀번호 리셋 기능
  - Articles 및 Users 리소스 CRUD 기능
  - Chat, Message, ToolCall 모델 및 마이그레이션
  - 라우팅 설정

---

## 주요 기술 스택 및 특징

### 백엔드
- **Ruby on Rails 8.x**: 메인 프레임워크
- **PostgreSQL**: 데이터베이스 (pg_search, vector embedding 지원)

### 프론트엔드
- **Hotwire (Turbo + Stimulus)**: SPA-like 사용자 경험
- **Tailwind CSS: 현대적이고 반응형 UI
- **Kramdown**: Markdown 렌더링

### AI 및 자동화
- **RubyLLM**: AI 기반 콘텐츠 생성 및 요약
- **Gemini 2.5 Flash**: 기사 요약 및 메타데이터 생성
- **YouTube API**: 동영상 자막 추출
- **RSS 피드 처리**: 자동화된 콘텐츠 수집

### 개발 도구
- **Sorbet + RBS**: 정적 타입 검사
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
6. **Vector Embedding**: 유사 기사 추천
7. **SEO 최적화**: 메타 태그 및 사이트맵 자동 생성
