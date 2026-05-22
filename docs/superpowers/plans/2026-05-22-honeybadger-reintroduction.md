# Honeybadger Reintroduction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** production 환경에 Honeybadger 예외 추적과 배포 추적을 다시 도입하고, AppSignal은 유지한 채 OpenTelemetry는 Honeybadger 도입에 필요한 범위만 제거한다.

**Architecture:** Rails 런타임에는 `honeybadger` gem과 `config/honeybadger.yml`로 예외 추적을 연결하고, `ApplicationJob`은 공통 잡 컨텍스트를 Honeybadger notice에 실어 보낸다. 배포 추적은 GitHub Actions release 워크플로에서 성공적인 rollout 직후 Honeybadger Deploy API로 알린다.

**Tech Stack:** Rails 8, Active Job, Minitest, Honeybadger Ruby gem, GitHub Actions

---

### Task 1: ApplicationJob notice 컨텍스트 보호

**Files:**
- Modify: `app/jobs/application_job.rb`
- Create: `test/jobs/application_job_test.rb`

- [ ] `ApplicationJob` 예외 처리용 failing test를 추가한다.
- [ ] 테스트를 단독 실행해 Honeybadger notify/context 기대값으로 실패하는지 확인한다.
- [ ] `ApplicationJob`에 Honeybadger notify 래핑과 안전한 fallback을 최소 구현한다.
- [ ] 단독 테스트를 다시 실행해 통과를 확인한다.

### Task 2: Honeybadger 설정 추가와 OTel 최소 제거

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Create: `config/honeybadger.yml`
- Delete: `config/initializers/opentelemetry.rb`
- Modify: `config/environments/production.rb`

- [ ] `honeybadger` gem을 추가하고 `opentelemetry-*` gem만 제거한다.
- [ ] production 전용 `config/honeybadger.yml`을 추가한다.
- [ ] production 환경 주석/설정에서 OTel 의존 흔적을 제거한다.
- [ ] 관련 파일을 `rails_validate`로 검증한다.

### Task 3: 배포 추적과 운영 문서 정리

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `README.md`

- [ ] release 워크플로에 Honeybadger deployment notification step을 추가한다.
- [ ] README의 운영/환경 설정 문구를 실제 스택과 맞게 정리한다.
- [ ] release 워크플로와 README를 검증한다.

### Task 4: 통합 검증

**Files:**
- Modify: `graphify-out/*` (generated)

- [ ] `bundle install`로 lockfile을 갱신한다.
- [ ] 관련 테스트, `rails_validate`, `bin/rake quality`를 실행한다.
- [ ] graphify rebuild를 실행해 그래프를 최신화한다.
