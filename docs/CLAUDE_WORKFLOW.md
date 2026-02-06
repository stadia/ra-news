# Claude Code Workflow Guidelines

이 문서는 Claude Code 사용 시 효율적인 작업 패턴을 정의합니다.

> **참고**: 프로젝트 개요 및 코드 컨벤션은 [AGENTS.md](../AGENTS.md)를 참조하세요.

---

## 작업 범위 설정 원칙

**단일 세션에서 완료 가능한 작업 단위로 분할:**
- 레이아웃/UI 리디자인은 3-4단계로 나누어 각 단계를 독립적으로 완료 및 검증
- 각 단계는 테스트 가능하고 커밋 가능한 상태로 종료
- 다음 단계로 진행하기 전에 명시적으로 완료 확인

### 레이아웃/UI 작업 분할 예시

```
❌ 나쁜 예: "전체 레이아웃을 Tailwind 사이드바로 변경해주세요"
→ 세션이 중간에 끊기고 부분 완료 상태로 남음

✅ 좋은 예: 단계별 분할

Phase 1: 사이드바 HTML 구조 생성 (토글 기능 제외)
  - 기본 Tailwind 클래스로 레이아웃 구조만 생성
  - 완료 후 커밋 & 다음 단계 진행

Phase 2: Stimulus 컨트롤러로 토글 기능 추가
  - data-controller 및 data-action 연결
  - 완료 후 커밋 & 다음 단계 진행

Phase 3: 반응형 스타일 및 애니메이션 추가
  - Tailwind breakpoint 클래스 적용
  - 완료 후 최종 커밋
```

---

## PR 리뷰 워크플로우

PR 코멘트를 가져와 수정을 적용할 때는 **하나의 완전한 사이클**로 처리:

```bash
# 1. PR 코멘트 전체 가져오기
gh pr view --comments

# 2. 모든 요청 사항을 파일별로 그룹화하여 리스트업

# 3. 모든 변경 사항을 순차적으로 적용

# 4. 테스트 실행으로 검증
bin/rails test
bin/rubocop --autocorrect-all

# 5. 변경 사항 요약 및 커밋
git commit -m "Address PR review feedback

- Fixed <issue 1> in <file>
- Updated <issue 2> in <file>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**중요:** 세션이 끊기기 전에 모든 리뷰 코멘트를 처리하고 커밋까지 완료해야 합니다.

---

## 자율성과 명시적 검증의 균형

### 높은 자율성이 유용한 경우
- 명확한 목표가 있는 리팩토링
- 패턴이 확립된 반복 작업
- 테스트 스위트가 잘 갖춰진 변경 사항

### 명시적 검증이 필요한 경우
- 레이아웃/UI 변경 (시각적 확인 필요)
- 데이터베이스 마이그레이션 (롤백 전략 확인 필요)
- 외부 API 연동 변경 (실제 환경에서 테스트 필요)

### 단계 완료 후 확인 요청 패턴

```
"Phase 1이 완료되었습니다. 다음을 확인해주세요:
- app/views/layouts/application.html.erb:15-45 (사이드바 구조)
- 기존 콘텐츠 영역이 정상 렌더링되는지 브라우저에서 확인

확인 후 Phase 2로 진행할까요?"
```

---

## 테스트 우선 검증

코드 변경 후 자동으로 검증:

```bash
# 관련 테스트만 실행 (빠른 피드백)
bin/rails test test/models/article_test.rb

# 전체 테스트 (주요 변경 시)
bin/rails test

# 타입 체크 (서비스/모델 변경 시)
bundle exec steep check

# 스타일 체크 및 자동 수정
bin/rubocop --autocorrect-all
```

**원칙:** 편집 후 즉시 관련 테스트를 실행하여 회귀를 조기 발견합니다.

---

## 커밋 전략

### 빈번한 작은 커밋 선호
- 각 논리적 단위(Phase)마다 커밋
- 커밋 메시지에 변경 이유와 영향 범위 명시
- 테스트가 통과하는 상태에서만 커밋

### 커밋 메시지 템플릿

```
[타입] 간결한 제목 (50자 이내)

- 변경 사항 1 (파일:라인)
- 변경 사항 2 (파일:라인)
- 테스트 결과: bin/rails test 통과

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 타입 분류
| 타입 | 설명 |
|------|------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 리팩토링 |
| `style` | UI/레이아웃 변경 |
| `test` | 테스트 추가/수정 |
| `docs` | 문서 변경 |
