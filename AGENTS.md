# AGENTS.md

AI 에이전트를 위한 프로젝트 룰북입니다.

## 절대 규칙

- 모든 응답은 한국어로 작성하고, 로그와 명령어 출력은 원문 그대로 유지한다.
- 코드 변경 전후의 맥락과 테스트 결과를 커밋 메시지 또는 PR 설명에 기록한다.
- 테스트와 검증은 PostgreSQL 기준으로 수행하며, 필요하면 `TEST_DATABASE_URL`을 우선 사용한다.
- PostgreSQL 확장이 필요한 이 프로젝트를 SQLite 기준으로 해석하거나 검증하지 않는다.
- 인증은 Devise가 아니라 현재의 custom auth와 `Current.user` 패턴을 기준으로 다룬다.
- `Article`의 AI 요약, embedding, soft-delete(`discarded_at`), `social_post_ids` JSONB 구조를 무시하고 수정하지 않는다.
- `Site.kind` enum(RSS/YouTube/Gmail/HN) 제약을 무시하지 않는다.
- 댓글 기능 수정 시 `awesome_nested_set` 구조와 `Comment::MAX_DEPTH` 제한을 깨뜨리지 않는다.
- 프론트엔드 클래스명은 Tailwind CSS v4.2 기준으로 작성하며, 새 코드에 v3 클래스명을 그대로 쓰지 않는다.
- Tailwind CSS 색상 클래스는 직접 쓰지 않고, 항상 시맨틱 토큰을 사용한다.
- 기본 locale은 한국어로 유지하고, 새 번역 키는 `config/locales/ko.yml`에 추가한다.
- 날짜와 시간 표시는 `l(Time.current, format: :short)` 규칙을 따른다.
- PostgreSQL 확장, 한국어 요약, 로컬라이제이션 등 운영 환경 전제를 무시한 채 production과 다른 방향으로 구현하지 않는다.

## 권장 규칙

- 변경 작업 전 `Article`, `Site`, `User`, `Comment`의 역할과 제약을 먼저 확인하고 영향 범위를 검토한다.
- Ruby 코드에 타입 힌트를 추가하거나 수정할 때는 inline RBS 스타일을 사용한다.
- 서비스 객체를 만들거나 수정할 때는 기존 `OperationService`와 `Dry::Operation` 패턴 중 문맥에 맞는 방식을 따른다.
- 소셜 미디어 연동 코드는 `SocialMediaService` 기반 구조와 플랫폼별 서비스 분리를 유지한다.
- 변경을 마무리하기 전에 테스트 여부와 미실행 사유를 명확히 남긴다.
- 관련 배경 문서가 필요하면 `docs/CLAUDE_WORKFLOW.md`, `docs/postgresql-extensions.md`를 우선 참고한다.

## 도구 사용 규칙

- 라이브러리나 런타임 구조를 조사할 때는 가능한 경우 Serena, Rails MCP Server, Context7, Sequential Thinking 같은 제공 도구를 목적에 맞게 사용한다.
- 제공된 MCP 도구가 더 적합한 작업인데 무조건 파일 전체를 읽거나 비효율적인 방식만 고집하지 않는다.
- Serena를 처음 사용할 때는 `activate_project("ruby-news")`를 먼저 실행한다.
- Rails 구조 확인이 필요하면 Rails MCP Server를 우선 고려한다.
- 최신 라이브러리 문서나 예제가 필요하면 Context7을 사용하고, `resolve-library-id` 후 `query-docs` 순서로 진행한다.
- 복잡한 문제를 단계적으로 풀어야 할 때는 Sequential Thinking을 사용한다.
