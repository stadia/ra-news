# lexxy 로딩 레이어 원복 설계

날짜: 2026-07-13
상태: 승인됨

## 배경

lexxy 리치텍스트 에디터의 로딩 문제(에디터가 뒤늦게 나타남, Turbo 캐시 재방문 시
빈 화면)를 해결하기 위해 여러 로딩 최적화를 시도했으나 해결하지 못했다. 따라서
lexxy 설치 시점의 단순 로딩 방식(eager 전역 로딩)으로 되돌리기로 결론내렸다.

## 근본 원인 분석

빈 화면 문제의 근본 원인은 lazy loading 최적화 도입으로 인한 **회귀**였다.
`turbo:before-cache`에서 lexxy가 에디터 DOM을 지우고 캐시하는 동작이, lazy 로드
환경에서 재방문 시 빈 스냅샷을 프리뷰로 보이게 만들었다. `turbo_permanent` 밴드에이드
(`95f1b9ec`, `045102ae`)는 이 회귀에 대한 임시 조치였다. eager 전역 로딩으로
되돌리면 근본 원인이 제거되므로 밴드에이드도 함께 제거한다.

## 범위

**원복(로딩 레이어만):** lexxy 로딩 메커니즘을 최초 설치 시절 eager 전역 로딩으로.
lexxy 사용처(댓글/답글/장문/madmin)는 그대로 유지.

**기준 baseline:** 최적화 커밋 직전 상태 `41a9d4f8`의 로딩 동작.
- `application.js`: 최상위 `import "lexxy";`
- `config/importmap.rb`: `pin "lexxy", to: "lexxy.js"` (preload 기본 true)
- `app/components/layout.rb`: head에서 `stylesheet_link_tag "lexxy", data_turbo_track: "reload"`

## 파일별 편집 내용

### 1. `app/javascript/application.js`
- 제거: `turbo:load` 리스너 블록 전체(`lexxy-editor` 탐지 → 동적 `import("lexxy")` +
  Sentry 에러 핸들링)와 위 3줄 주석
- 복원: `import "lexxy";` 한 줄을 `import "@rails/activestorage";` 직후,
  `import "controllers";` 이전에 배치(baseline 순서)

### 2. `config/importmap.rb`
- `pin "lexxy", to: "lexxy.min.js", preload: false` + 위 4줄 주석 →
  `pin "lexxy", to: "lexxy.min.js"` (preload 기본값 true = 전역 modulepreload)
- `lexxy.min.js` 파일명은 버그 수정(비압축 917KB → 604KB)이므로 유지

### 3. `app/components/layout.rb`
- 3줄 주석 블록(전역 로드 안 함 설명) →
  `stylesheet_link_tag "lexxy", data_turbo_track: "reload"` 한 줄로 복원
- `render_lexxy_stylesheet` 메서드 정의는 이미 `edb75ccd`에서 제거됐으므로 추가 조치 없음

### 4. `app/components/base.rb`
- `lexxy_editor_asset_tags` 메서드 본체 + 위 22줄 주석 블록 전체 삭제

### 5. `app/components/posts/post_form.rb`
- `lexxy_editor_asset_tags` 한 줄 삭제
- `data` 해시에서 `turbo_permanent: true`와 위 5줄 주석 제거 →
  `action:` 라인을 원래 단일 라인 형태로 복원

### 6. `app/components/posts/blog_editor.rb`
- `lexxy_editor_asset_tags` 한 줄 삭제
- (blog_editor는 turbo_permanent 미적용이었으므로 이것만)

### 7. `app/components/comments/comment_form.rb`
- `lexxy_editor_asset_tags` 삭제
- `turbo_frame_tag("new_comment_#{@article.id}", data: { turbo_permanent: true })` →
  `turbo_frame_tag("new_comment")` 로 복원 + 위 5줄 주석 삭제

### 8. `app/components/comments/comment_reply_form.rb`
- `lexxy_editor_asset_tags` 삭제
- `data: { reply_form_target: "form", turbo_permanent: true }` →
  `data: { reply_form_target: "form" }` 복원 + 위 2줄 주석 삭제

## 보존/제외 항목

**제외(원복하지 않음, 유지):**
- `app/views/layouts/federails/application.html.erb:61`의 `stylesheet_link_tag "lexxy"`
  — federails(연합 관리) 전용 레이아웃, 최적화 이전부터 존재(`ba3fedd9`). 별도 영역.
- `lexxy.min.js` 파일명 — `95f1b9ec`의 독립적 버그 수정. 다른 pin과 일관되므로 유지.
- `.rubocop.yml` Layout `Metrics/ClassLength` 예외 — 기존 부채. 무해하므로 유지.
- `asset_preconnect` 기능 + `test/components/layout_asset_preconnect_test.rb`
  — asset_host preconnect 검증, lexxy 로딩과 무관. 통과 유지.
- character-counter, 접근성 개선, lightbox/lightgallery lazy 로딩 — lexxy와 무관한 별개 작업. 유지.

## 트레이드오프 (명시적 수용)

eager 전역 로딩 복원 시 **에디터 없는 페이지도 lexxy JS(~604KB) + CSS를 매번 로드**.
이는 최초 설치 상태의 원래 동작이자 사용자가 수용한 비용. 비에디터 페이지 성능 저하 감수.

## 검증

### 편집 직후
- 각 파일 편집 후 `rails 'ai:tool[validate]' files=... level=rails` 로 구문+의미 검증
- 8개 파일 전부 validate 통과

### 자동화 테스트
- `bundle exec rspec` / `bin/rails test` 실행
  - `test/components/layout_asset_preconnect_test.rb` — 무관 기능, 통과 유지 확인
  - 폼 렌더 관련 테스트 깨지는 것 없는지 확인
- `rake quality`(커버리지+Flog) 통과

### 수동 동작 검증 (핵심)
1. **에디터 정상 렌더링**: `/feed`(글쓰기 폼), 기사 상세(댓글/답글 폼), 블로그 편집 —
   lexxy 에디터 즉시 표시(뒤늦게 나타나는 지연 없어야 함)
2. **Turbo 캐시 재방문 빈 화면 미발생**: 에디터 페이지 → 다른 페이지 → 뒤로가기 시
   빈 화면 점멸 없는지 확인. eager 원복으로 사라져야 함
3. **비에디터 페이지 정상**: 홈/기사 목록 — eager 로드되더라도 동작 문제 없는지 확인

### graphify 동기화
- 코드 파일 수정 후 `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` 실행

## 커밋

- 검증 완료 후 단일 커밋(메시지: "lexxy 로딩 레이어를 최초 설치 시절 eager 전역 로딩으로 원복")
- 커밋은 사용자 확인 후에만