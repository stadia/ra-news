---
name: pr-fix
description: PR 리뷰 코멘트를 가져와 모든 요청 사항을 자동으로 적용하고 검증하는 워크플로우
---

# PR Fix Workflow

이 스킬은 PR 리뷰 코멘트를 가져와서 모든 요청 사항을 한 번에 적용하고 검증하는 자동화된 워크플로우를 제공합니다.

## 실행 순서

### 1단계: PR 코멘트 가져오기
현재 브랜치의 PR에 달린 모든 리뷰 코멘트를 가져옵니다.

```bash
gh pr view --comments
```

**예외 처리:**
- PR이 없는 경우: 사용자에게 PR을 먼저 생성하라고 안내
- gh CLI가 없는 경우: 설치 방법 안내

### 2단계: 코멘트 분석 및 그룹화
가져온 모든 리뷰 코멘트를 다음 기준으로 분류합니다:

- **파일별 그룹화**: 같은 파일에 대한 코멘트를 묶음
- **우선순위 지정**:
  - 🔴 필수 변경 (버그, 보안 이슈)
  - 🟡 권장 변경 (리팩토링, 성능 개선)
  - 🟢 제안 (스타일, 문서화)
- **액션 아이템 추출**: 각 코멘트를 구체적인 작업으로 변환

**출력 형식:**
```
=== PR Review Feedback Summary ===

📁 app/models/article.rb
  🔴 [필수] Line 45: N+1 쿼리 방지를 위해 includes 추가 필요
  🟡 [권장] Line 78: 메서드 extract_summary를 별도 서비스로 분리 권장

📁 app/controllers/articles_controller.rb
  🔴 [필수] Line 23: 인증 없이 destroy 액션 호출 가능 (before_action 추가)
  🟢 [제안] Line 15: 변수명 a를 article로 변경

총 4개 액션 아이템 (필수 2개, 권장 1개, 제안 1개)
```

### 3단계: 모든 변경 사항 적용
파일별로 순차적으로 변경 사항을 적용합니다.

**적용 원칙:**
1. 파일을 Read 도구로 먼저 읽어 전체 컨텍스트 파악
2. Edit 도구로 정확한 변경 적용 (Write는 신규 파일에만 사용)
3. 변경 후 해당 파일의 영향을 받는 테스트 파악
4. 우선순위 높은 것부터 처리 (🔴 → 🟡 → 🟢)

**주의사항:**
- 여러 코멘트가 같은 코드 블록에 대한 것이면 한 번에 처리
- 변경이 다른 파일에 영향을 주는 경우 연쇄 수정
- RBS 타입 시그니처가 있는 경우 함께 업데이트

### 4단계: 테스트 실행 및 검증
모든 변경 사항 적용 후 검증을 수행합니다.

```bash
# 4-1. 영향받는 테스트 파일만 먼저 실행 (빠른 피드백)
bin/rails test test/models/article_test.rb test/controllers/articles_controller_test.rb

# 4-2. RuboCop 자동 수정
bin/rubocop --autocorrect-all

# 4-3. 전체 테스트 스위트 실행
bin/rails test

# 4-4. (선택) Steep 타입 체크 (서비스/모델 변경 시)
bundle exec steep check
```

**실패 시 처리:**
- 테스트 실패: 실패 원인 분석하고 수정 후 재실행
- RuboCop 오류: 자동 수정으로 해결 안 되면 수동 수정
- Steep 오류: RBS 시그니처 업데이트

### 5단계: 변경 사항 커밋
모든 검증이 통과하면 커밋을 생성합니다.

```bash
# 변경된 파일만 스테이징
git add <modified_files>

# 커밋 메시지 생성
git commit -m "Address PR review feedback

적용한 변경 사항:
- app/models/article.rb:45 - N+1 쿼리 방지 (includes 추가)
- app/models/article.rb:78 - extract_summary를 SummaryService로 분리
- app/controllers/articles_controller.rb:23 - destroy 액션에 인증 추가
- app/controllers/articles_controller.rb:15 - 변수명 개선 (a → article)

테스트 결과: bin/rails test 통과 ✓
RuboCop: 모든 위반 수정 ✓

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 6단계: 결과 요약 및 확인 요청
사용자에게 다음 정보를 제공합니다:

```
=== PR Fix 완료 ===

✅ 적용 완료: 4개 액션 아이템
   - 필수 변경: 2개
   - 권장 변경: 1개
   - 제안: 1개

📝 수정된 파일:
   - app/models/article.rb (2곳)
   - app/controllers/articles_controller.rb (2곳)
   - app/services/summary_service.rb (신규)
   - test/services/summary_service_test.rb (신규)

🧪 테스트 결과:
   - bin/rails test: 통과 (143 runs, 0 failures)
   - bin/rubocop: 위반 없음
   - bundle exec steep check: 타입 오류 없음

📦 커밋 생성:
   - SHA: a1b2c3d
   - Message: "Address PR review feedback"

다음 단계:
1. 변경 사항을 브라우저에서 확인
2. 필요시 추가 수정
3. git push로 원격 브랜치에 반영
```

## 에러 핸들링

### PR이 없는 경우
```
❌ 현재 브랜치에 연결된 PR이 없습니다.

다음 명령어로 PR을 먼저 생성해주세요:
  gh pr create --title "..." --body "..."

또는 기존 PR을 현재 브랜치와 연결해주세요.
```

### 리뷰 코멘트가 없는 경우
```
✅ 리뷰 코멘트가 없습니다. PR이 승인된 상태이거나 아직 리뷰가 시작되지 않았습니다.
```

### 테스트 실패 시
```
❌ 테스트 실패: test/models/article_test.rb

실패 원인 분석 중...
→ ArticleTest#test_summary_generation: NoMethodError: undefined method `generate_summary'

수정 방안:
1. SummaryService#call 메서드명을 generate_summary로 변경
2. 또는 테스트에서 SummaryService.call 사용

자동 수정을 시도하겠습니다...
```

## 사용 예시

### 기본 사용
```
/pr-fix
```

### 특정 우선순위만 처리
```
/pr-fix --priority critical
→ 🔴 필수 변경 사항만 적용
```

### Dry-run 모드 (실제 변경 없이 계획만 확인)
```
/pr-fix --dry-run
→ 어떤 변경이 적용될지 미리 확인
```

## 제약 사항

- gh CLI가 설치되어 있어야 함
- PR이 생성되어 있어야 함
- 리뷰 코멘트가 구체적인 액션을 포함해야 함 (모호한 코멘트는 수동 확인 필요)

## 통합 워크플로우

이 스킬은 AGENTS.md의 "PR 리뷰 워크플로우" 섹션을 자동화합니다. 수동으로 단계별 진행이 필요한 경우 해당 섹션을 참고하세요.
