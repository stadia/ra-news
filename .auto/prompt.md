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
- 이번 연구는 그 과거 결정을 그대로 답으로 쓰지 않고, 동일 스냅샷과 동일 결함 corpus로 재검증한다.
