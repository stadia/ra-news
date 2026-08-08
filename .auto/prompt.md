# Autoresearch: Ruby 타입 체커 선정

## Objective
Ruby 4.0 / Rails 8.1 기반 RubyNews에서 단일 정적 타입 체커를 선정한다. 후보는 RBS/RBI 인라인 주석을 직접 읽는 Sorbet과, rbs-inline 생성물 및 RBS collection을 읽는 Steep이다. 실제 프로젝트와 가까운 고정 스냅샷(`e0f5de7c`)에 대표 타입 결함을 주입해 검출력을 우선 비교한다.

벤치마크 전용 코드나 판정 규칙에 맞춘 편법은 금지한다. 후보별로 같은 결함, 같은 소스 스냅샷을 사용하고, 한 후보에만 유리한 구문은 쓰지 않는다. 실행시간이나 생성 파일 크기를 줄이려고 검사 범위를 축소해서도 안 된다.

## Metrics
- **Primary**: `defects_detected` (개, 높을수록 좋음) — 대표 결함 9개 중 해당 소스 줄을 실제 오류로 보고한 수
- **Secondary**: `false_positives`, `typecheck_seconds`, `support_kb`, `baseline_errors` — 오탐, 전체 검사 시간, 지원 파일 크기, probe 없는 기존 오류

Primary가 같으면 오탐 0을 전제로 지원 파일 크기와 실행시간, Ruby/Rails 호환성, 생성물 드리프트 위험을 함께 판단한다. Secondary를 개선하려고 Primary 검출력을 희생하지 않는다.

## How to Run
`./.auto/measure.sh` — `.auto/candidate`의 `steep` 또는 `sorbet`을 읽고 구조화된 METRIC을 출력한다.

스크립트는 `tmp/autoresearch-typechecker-e0`에 detached worktree를 만들고 매 실행마다 고정 커밋으로 초기화한다. 따라서 현재 제품 코드나 사용자 작업을 변경하지 않는다.

## Files in Scope
- `.auto/candidate` — 현재 비교 후보
- `.auto/typecheck_probe.rb` — 양쪽 후보에 동일하게 주입하는 대표 결함 corpus
- `.auto/measure.sh` — 공정한 측정 및 진단 파서
- `.auto/checks.sh` — 벤치마크 무결성 검사
- `.auto/prompt.md`, `.auto/ideas.md` — 연구 기록

## Off Limits
- `app/`, `lib/`, `config/`, `db/` 등 제품 코드
- 후보별로 다른 probe 또는 다른 검사 디렉터리 사용
- 오류 은폐 설정 추가, 진단 severity 완화, `typed: false` 사용
- 고정 스냅샷의 기존 타입 설정 변경
- 테스트/타입 체커 출력 위조 또는 METRIC 상수화

## Constraints
- Ruby 4.0.6과 Rails 8.1.3 전제를 유지한다.
- 두 후보 모두 전체 기존 검사 범위를 실행한다.
- 결함 검출은 단순 exit code가 아니라 probe의 서로 다른 결함 줄을 기준으로 센다.
- probe 없는 baseline 오류를 별도 측정해 기존 오류를 결함 검출로 세지 않는다.
- 생성 단계(rbs-inline)가 필요한 Steep은 그 비용과 드리프트를 포함한다.
- 현재 워킹트리의 사용자 변경 `.mcp.json` 삭제는 stash로 보존했으며 연구 커밋에 포함하지 않는다.

## What's Been Tried
- 프로젝트 이력상 Steep 2.0은 strict 기준에서 12,844개 진단 중 12,292개가 Rails/Phlex/RBS 공백으로 인해 실질 강제 불가능했다.
- 같은 이력에서 Sorbet은 Tapioca RBI를 사용해 앱 파일 시길 50.5%, 메서드 시그니처 27.6%를 측정했고 이후 단일 체커로 전환되었다.
- 이번 연구는 그 과거 결정을 그대로 답으로 쓰지 않고, 동일 스냅샷과 동일 결함 corpus로 재검증했다.
- Steep의 현재 실용 설정은 9개 중 3개(33.3%)를 검출했고 6개를 놓쳤다. 18초 안팎이 걸렸으며 지원 파일은 약 0.8MB다.
- Sorbet은 동일 corpus에서 9개 중 7개(77.8%)를 검출했고 cold 1.94초, warm 0.43초였다. 지원 RBI는 약 37MB로 크다.
- Steep의 모든 진단을 strict로 올리면 8개(88.9%)를 잡지만 기존 코드에서 12,701건이 발생해 CI 게이트로 사용할 수 없다. 이를 DEBT/hint로 완화하면 다시 3개만 강제된다.
- Steep에 `rbs_rails` 0.13.1과 실제 PostgreSQL schema를 추가한 공정성 실험도 3/9로 개선이 없었고, 기존 RBS collection/shim과 충돌해 baseline 진단 68건이 생겼다.
- 초기 corpus의 Rails setter 항목은 `Article#title = 123`이었지만, 검증 결과 앱이 `title=(value)`를 `(untyped) -> void`로 의도적으로 오버라이드하고 비문자열을 그대로 허용했다. 이는 실제 결함이 아니므로 benchmark mislabeled case였다.
- Rails setter 항목을 동일한 nullable string column이면서 커스텀 writer가 없는 `Article#slug = 123`으로 교정했다. schema와 generated RBI의 `String?` 계약, source override 부재를 rails-ai-context로 검증했다. workload 변경이므로 새 experiment segment를 시작한다.
- 결론: 현 프로젝트에서는 **Sorbet + Tapioca + inline RBS comments**를 단일 타입 검사 경로로 유지한다. Steep 재도입은 Rails/Phlex RBS 생태계가 baseline strict를 감당할 때 재평가한다.
