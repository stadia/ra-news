---
name: fullstack-orchestrator
description: "AlNews Rails 풀스택 기능 개발을 전문가 에이전트들로 조율하는 오케스트레이터. 새 기능 추가, 기존 기능 수정, 버그 수정, 리팩토링 등 여러 Rails 레이어에 걸친 작업을 분석하고 적절한 전문가(모델/컨트롤러/뷰/Stimulus/잡/서비스/테스트)를 순차 호출하여 구현한다. '기능 구현해줘', '풀스택으로 만들어줘', 여러 레이어에 걸친 변경이 필요한 모든 요청에 이 스킬을 사용할 것."
---

# AlNews Fullstack Orchestrator

AlNews 프로젝트의 풀스택 작업을 전문가 에이전트로 조율하는 오케스트레이터.

## 실행 모드: 서브 에이전트

Rails 풀스택 작업은 레이어 간 순차 의존성이 강하다 (모델→컨트롤러→뷰). 각 전문가의 결과물이 다음 전문가의 입력이 되므로 서브 에이전트 모드가 적합하다.

## 에이전트 구성

| 에이전트 | subagent_type | 역할 | 호출 조건 |
|---------|--------------|------|----------|
| rails-architect | rails-architect | 요구사항 분석, 구현 계획 | 항상 (Phase 1) |
| models-specialist | models-specialist | 스키마, 모델, 마이그레이션 | DB 변경 필요 시 |
| service-objects-specialist | service-objects-specialist | 비즈니스 로직, 서비스 객체 | 복잡한 로직 필요 시 |
| background-jobs-specialist | background-jobs-specialist | 백그라운드 잡 | 비동기 처리 필요 시 |
| rails-controller-specialist | rails-controller-specialist | 컨트롤러, 라우트 | API/페이지 엔드포인트 필요 시 |
| rails-views-specialist | rails-views-specialist | 뷰 템플릿, 파셜, 컴포넌트 | UI 변경 필요 시 |
| stimulus-turbo-specialist | stimulus-turbo-specialist | Stimulus 컨트롤러, Turbo | 인터랙티브 기능 필요 시 |
| minitest-specialist | minitest-specialist | 테스트 작성 | 항상 (Phase 마지막) |
| qa-specialist | qa-specialist | 통합 검증 | 항상 (최종 Phase) |

## 워크플로우

### Phase 1: 분석 및 계획

rails-architect를 호출하여 요구사항을 분석한다.

```
Agent(
  description: "기능 분석 및 구현 계획",
  subagent_type: "rails-architect",
  model: "opus",
  prompt: "다음 요구사항을 분석하고 구현 계획을 세워라: {user_request}

    출력 형식:
    1. 영향받는 레이어 (model/controller/view/job/service/stimulus)
    2. 각 레이어별 변경 사항
    3. 구현 순서
    4. 주의사항

    MCP 도구를 활용하여 기존 코드 구조를 먼저 파악하라."
)
```

분석 결과를 바탕으로 필요한 에이전트만 순차 호출한다.

### Phase 2: 백엔드 구현 (순차)

영향받는 레이어에 따라 순서대로 호출:

**2-1. 모델/마이그레이션** (DB 변경 필요 시)
```
Agent(
  description: "모델 및 마이그레이션 생성",
  subagent_type: "models-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 다음을 구현하라: {model_tasks}
    - 마이그레이션 생성 후 bin/rails db:migrate 실행
    - rails_validate로 검증"
)
```

**2-2. 서비스 객체** (복잡한 비즈니스 로직 시)
```
Agent(
  description: "서비스 객체 구현",
  subagent_type: "service-objects-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 서비스 객체를 구현하라: {service_tasks}"
)
```

**2-3. 백그라운드 잡** (비동기 처리 시)
```
Agent(
  description: "백그라운드 잡 구현",
  subagent_type: "background-jobs-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 잡을 구현하라: {job_tasks}"
)
```

**2-4. 컨트롤러/라우트**
```
Agent(
  description: "컨트롤러 및 라우트 구현",
  subagent_type: "rails-controller-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 컨트롤러를 구현하라: {controller_tasks}
    - rails_validate로 검증"
)
```

### Phase 3: 프론트엔드 구현 (순차)

**3-1. 뷰/컴포넌트**
```
Agent(
  description: "뷰 및 컴포넌트 구현",
  subagent_type: "rails-views-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 뷰를 구현하라: {view_tasks}
    - 프로젝트 디자인 시스템을 따를 것 (rails_get_design_system 참조)
    - rails_validate로 검증"
)
```

**3-2. Stimulus/Turbo** (인터랙티브 기능 시)
```
Agent(
  description: "Stimulus 컨트롤러 및 Turbo 구현",
  subagent_type: "stimulus-turbo-specialist",
  model: "opus",
  prompt: "Phase 1 계획에 따라 인터랙티브 기능을 구현하라: {stimulus_tasks}"
)
```

### Phase 4: 테스트

```
Agent(
  description: "테스트 작성 및 실행",
  subagent_type: "minitest-specialist",
  model: "opus",
  prompt: "구현된 기능에 대한 테스트를 작성하고 실행하라: {test_scope}
    - 모델 테스트, 컨트롤러 테스트, 시스템 테스트 포함
    - bin/rails test 로 전체 실행"
)
```

### Phase 5: QA 검증

```
Agent(
  description: "통합 품질 검증",
  subagent_type: "qa-specialist",
  model: "opus",
  prompt: "다음 변경 사항의 통합 품질을 검증하라:
    변경 파일: {changed_files}
    기능 설명: {feature_description}

    경계면 교차 비교를 수행하고 검증 보고서를 제출하라."
)
```

### Phase 6: 보고

사용자에게 결과 요약:
- 구현된 항목 목록
- 변경된 파일 목록
- 테스트 결과
- QA 검증 결과
- 남은 작업 (있다면)

## 에이전트 선택 매트릭스

| 작업 유형 | 호출 에이전트 |
|----------|-------------|
| 새 모델/필드 추가 | architect → models → controller → views → tests → qa |
| API 엔드포인트 추가 | architect → controller → tests → qa |
| UI 변경만 | architect → views → stimulus → tests → qa |
| 백그라운드 처리 추가 | architect → models → service → jobs → tests → qa |
| 버그 수정 (단일 레이어) | 해당 레이어 전문가 1명 + qa |
| 리팩토링 | architect → 해당 전문가들 → tests → qa |

## 데이터 흐름

```
[사용자 요청]
    ↓
[architect] → 구현 계획
    ↓
[models] → 스키마/모델 변경
    ↓
[service/jobs] → 비즈니스 로직 (선택)
    ↓
[controller] → 엔드포인트
    ↓
[views/stimulus] → UI
    ↓
[minitest] → 테스트
    ↓
[qa] → 검증 보고서
    ↓
[사용자에게 결과 보고]
```

## 에러 핸들링

| 상황 | 전략 |
|------|------|
| 에이전트 1개 실패 | 에러 분석 후 1회 재시도. 재실패 시 사용자에게 알림 |
| 마이그레이션 실패 | 즉시 중단, 롤백 후 사용자에게 알림 |
| 테스트 실패 | 실패 원인 분석 후 해당 레이어 전문가 재호출 |
| QA 문제 발견 | critical은 해당 전문가 재호출, warning/info는 보고서에 포함 |

## 테스트 시나리오

### 정상 흐름
1. "게시글에 북마크 기능 추가해줘"
2. architect가 모델(Bookmark) + 컨트롤러 + 뷰 + Stimulus 계획 수립
3. models-specialist가 Bookmark 모델/마이그레이션 생성
4. controller-specialist가 BookmarksController 생성
5. views-specialist가 북마크 버튼 UI 구현
6. stimulus-specialist가 토글 인터랙션 구현
7. minitest-specialist가 테스트 작성/실행
8. qa-specialist가 경계면 검증
9. 사용자에게 완료 보고

### 에러 흐름
1. "기사 상세 페이지에 관련 기사 추천 추가"
2. architect가 계획 수립 (임베딩 기반 유사도)
3. models-specialist 성공
4. controller-specialist에서 N+1 쿼리 경고
5. qa-specialist가 컨트롤러↔뷰 변수 불일치 발견 (critical)
6. controller-specialist 재호출하여 수정
7. qa-specialist 재검증 통과
8. 사용자에게 완료 보고 (중간 이슈 및 해결 과정 포함)
