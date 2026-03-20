# 디자인 시스템 개선 히스토리

> **생성일:** 2026-02-08
> **최종 업데이트:** 2026-03-19

---

## 완료된 개선사항

### Phase 1: CSS 변수 도입 ✅ (완료)

**tokens.css 생성 및 3-Tier 토큰 아키텍처 구축:**

- [x] `app/assets/tailwind/tokens.css` 생성
- [x] Primitive 토큰 정의 (Brand, Neutral, Status 색상)
- [x] Spacing, Border Radius, Shadow, Typography 토큰
- [x] Transition, Z-Index 토큰
- [x] `application.css`에서 import 및 `@theme inline` 연동

### Phase 2: 시맨틱 색상 토큰 도입 ✅ (완료)

**하드코딩된 Tailwind 색상 → 시맨틱 토큰 전환:**

- [x] Tier 2 시맨틱 토큰 정의 (`.theme-dark`, `.theme-light` 분기)
  - Background: `--color-bg-primary/secondary/tertiary/elevated`
  - Text: `--color-text-primary/secondary/muted/disabled`
  - Border: `--color-border`, `--color-border-light`, `--color-border-dark`
  - Accent: `--semantic-link`, `--semantic-accent-text`, `--semantic-brand-solid`
  - Status: `--semantic-danger-*`, `--semantic-info-*`
- [x] Tier 3 Tailwind 컴포넌트 별칭 정의 (`@theme inline`)
  - `bg-app`, `bg-surface`, `bg-surface-muted`, `bg-surface-elevated`
  - `text-content`, `text-content-secondary`, `text-content-muted`, `text-content-disabled`
  - `border-border-strong`, `border-border-muted`, `border-border-subtle`
  - `bg-brand-solid`, `bg-danger-solid`, `bg-info-solid` 및 hover 변형
  - `text-accent-text`, `text-link-hover`, `text-brand-foreground`
  - `ring-brand`, `ring-offset-app`

### Phase 3: View 파일 리팩토링 ✅ (완료)

**38+ 파일에서 하드코딩된 색상 클래스를 시맨틱 토큰으로 전환:**

주요 변환 패턴:

| Before (하드코딩) | After (시맨틱) |
|---|---|
| `bg-gray-800`, `bg-slate-800` | `bg-surface` |
| `bg-slate-900` | `bg-app` |
| `text-white`, `text-gray-100` | `text-content` |
| `text-gray-300`, `text-slate-200` | `text-content-secondary` |
| `text-gray-400`, `text-slate-400` | `text-content-muted` |
| `border-gray-700`, `border-slate-700` | `border-border-strong` |
| `text-green-400` | `text-accent-text` |
| `bg-green-600` | `bg-brand-solid` |
| `bg-blue-600` | `bg-info-solid` |
| `bg-slate-700 hover:bg-red-900` | `bg-surface-muted hover:bg-danger-solid` |
| `ring-green-500` | `ring-brand` |

**리팩토링 대상 (PR #605, #606 + feature/federails):**

Phlex 컴포넌트:
- [x] `app/components/articles/article.rb`
- [x] `app/components/articles/form.rb`
- [x] `app/components/comments/comment.rb`
- [x] `app/components/comments/comment_form.rb`
- [x] `app/components/comments/comment_header.rb`
- [x] `app/components/comments/comment_reply_form.rb`
- [x] `app/components/comments/delete_modal.rb`
- [x] `app/components/home/article.rb`
- [x] `app/components/layout.rb`
- [x] `app/components/login_required.rb`
- [x] `app/components/pagination.rb`
- [x] `app/components/push_notifications/prompt_modal.rb`
- [x] `app/components/recent_comments_sidebar.rb`
- [x] `app/components/users/form.rb`
- [x] `app/components/users/pwd_form.rb`
- [x] `app/components/users/user.rb`

Phlex View:
- [x] `app/views/articles/index.rb`, `new.rb`, `others.rb`, `show.rb`
- [x] `app/views/home/about.rb`
- [x] `app/views/passwords/edit.rb`, `new.rb`
- [x] `app/views/profiles/show.rb`, `follow_list.rb`
- [x] `app/views/sessions/new.rb`
- [x] `app/views/users/edit.rb`, `new.rb`, `password.rb`, `show.rb`
- [x] `app/views/actors/show.rb`, `lookup.rb`, `gone.rb`
- [x] `app/views/followings/follow_actions.rb`

ERB View:
- [x] `app/views/layouts/federails/application.html.erb`
- [x] `app/views/federails/client/followings/_follow_actions.html.erb`
- [x] `app/assets/tailwind/pagy-tailwind.css`

### Phase 4: 접근성 개선 ✅ (완료)

- [x] Skip Link 추가 (`Components::Layout`)
- [x] ARIA 레이블 추가 (네비게이션, 메뉴 토글)
- [x] `prefers-reduced-motion` 지원 (`tokens.css`)
- [x] 포커스 스타일 통합 (`.focus-visible-ring` 유틸리티)
- [x] Print 스타일 추가

### Phase 5: 라이트 테마 기반 ✅ (완료)

- [x] `.theme-light` / `.light` 선택자에 시맨틱 토큰 정의
- [x] `@custom-variant dark` 확장 (`.theme-dark` 지원)
- [x] RubyUI 변수 dark/light 분기 (`application.css`)
- [x] `body` 태그에 `theme-dark` 클래스 적용

---

## 미완료 / 향후 과제

### 라이트 모드 활성화
- [ ] 테마 전환 UI (토글 버튼/시스템 설정 연동)
- [ ] Stimulus 컨트롤러로 테마 전환 구현
- [ ] `localStorage` 기반 테마 유지
- [ ] `prefers-color-scheme` 미디어 쿼리 연동

### 어드민 뷰 시맨틱 토큰 적용
- [ ] `madmin/dashboard/show.html.erb` 하드코딩 색상 전환
- [ ] `madmin/social/index.html.erb` 하드코딩 색상 전환

### 추가 개선
- [ ] 접근성 자동 테스트 도입 (axe-core)
- [ ] Lighthouse Accessibility 95+ 검증

---

## 참고 문서

- [디자인 시스템 가이드](./DESIGN_SYSTEM.md) - 전체 토큰 체계 및 사용법
- [디자인 체크리스트](./DESIGN_CHECKLIST.md) - 빠른 참조용 체크리스트
- [코드 컨벤션](../AGENTS.md)

---

**마지막 업데이트:** 2026-03-19
