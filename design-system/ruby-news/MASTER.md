# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Ruby-News
**Generated:** 2026-02-08 11:51:48
**Category:** Space Tech / Aerospace

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Primary | `#1E293B` | `--color-primary` |
| Secondary | `#334155` | `--color-secondary` |
| CTA/Accent | `#22C55E` | `--color-cta` |
| Background | `#0F172A` | `--color-background` |
| Text | `#F8FAFC` | `--color-text` |

**Color Notes:** Dark tech + status green

### Typography

- **Heading Font:** Noto Sans KR
- **Body Font:** Noto Sans KR
- **Mood:** korean, modern, clean, professional, multilingual, readable
- **Google Fonts:** [Noto Sans KR + Noto Sans KR](https://fonts.google.com/share?selection.family=Noto+Sans+KR:wght@300;400;500;700)

**CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@300;400;500;700&display=swap');
```

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `--shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` | Cards, buttons |
| `--shadow-lg` | `0 10px 15px rgba(0,0,0,0.1)` | Modals, dropdowns |
| `--shadow-xl` | `0 20px 25px rgba(0,0,0,0.15)` | Hero images, featured cards |

---

## Component Specs

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: #22C55E;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: #1E293B;
  border: 2px solid #1E293B;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}
```

### Cards

```css
.card {
  background: #0F172A;
  border-radius: 12px;
  padding: 24px;
  box-shadow: var(--shadow-md);
  transition: all 200ms ease;
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  padding: 12px 16px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 200ms ease;
}

.input:focus {
  border-color: #1E293B;
  outline: none;
  box-shadow: 0 0 0 3px #1E293B20;
}
```

### Modals

```css
.modal-overlay {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: var(--shadow-xl);
  max-width: 500px;
  width: 90%;
}
```

---

## daisyUI Component Library

이 프로젝트는 **daisyUI v5** (Tailwind CSS 4 플러그인)를 사용합니다.

### 설정

- **플러그인:** `app/assets/tailwind/daisyui.mjs`
- **테마:** `app/assets/tailwind/daisyui-theme.mjs`
- **로드:** `app/assets/tailwind/application.css`에서 `@plugin "./daisyui.mjs"` 로 임포트

### 사용 중인 daisyUI 컴포넌트

| 컴포넌트 | daisyUI 클래스 | 사용 위치 |
|----------|---------------|----------|
| Button | `btn`, `btn-primary`, `btn-secondary`, `btn-danger`, `btn-outline`, `btn-sm/md/lg` | 헬퍼, Madmin, 폼 |
| Alert | `alert`, `alert-danger` | Flash 메시지, Madmin 폼 |
| Modal | `modal` 관련 커스텀 구현 | 댓글 삭제 확인 |

### 헬퍼 메서드

`ApplicationHelper`에서 daisyUI 버튼 클래스를 편리하게 사용하는 헬퍼 제공:

```ruby
# btn_class(variant:, size:, outline:, extra_classes:)
btn_class(variant: :primary, size: :sm)
# => "btn btn-primary btn-sm"

# btn_link_to - daisyUI 버튼 스타일 링크
btn_link_to "텍스트", path, variant: :secondary
```

### 테마 커스텀

daisyUI의 built-in 테마(dark, night, dim 등)를 기반으로 커스텀 테마를 `daisyui-theme.mjs`에서 정의 가능. 현재 프로젝트의 다크 모드 색상과 조합하여 사용.

### daisyUI + Tailwind 병용 규칙

- daisyUI 시맨틱 클래스 우선 사용 (`btn`, `alert` 등)
- daisyUI에 없는 세부 스타일은 Tailwind 유틸리티로 보완
- 색상은 디자인 시스템의 slate/green 팔레트 유지

---

## Style Guidelines

**Style:** Vibrant & Block-based

**Keywords:** Bold, energetic, playful, block layout, geometric shapes, high color contrast, duotone, modern, energetic

**Best For:** Startups, creative agencies, gaming, social media, youth-focused, entertainment, consumer

**Key Effects:** Large sections (48px+ gaps), animated patterns, bold hover (color shift), scroll-snap, large type (32px+), 200-300ms

### Page Pattern

**Pattern Name:** News Feed with Bento Grid

- **Conversion Strategy:** 정보 밀도 높은 뉴스 피드. 스캔하기 쉬운 카드 기반 레이아웃. 빠른 탐색 유도.
- **CTA Placement:** 기사 카드 내부 + 페이지네이션 하단
- **Section Order:** 1. Navigation, 2. Hero/Featured Article, 3. Article Grid (Bento), 4. Pagination, 5. Footer
- **Color Guidance:** 카드 배경 slate-800, 텍스트 slate-50/slate-200, 액센트 green-500
- **Effects:** 카드 호버 시 border-slate-600 + shadow-xl + translateY(-2px), 부드러운 전환 200ms
- **UX Notes:** 높은 정보 밀도를 유지하면서 가독성 확보. 모바일에서는 단일 컬럼 스택.

---

## Anti-Patterns (Do NOT Use)

- ❌ Flat design without depth
- ❌ Text-heavy pages

### Additional Forbidden Patterns

- ❌ **Emojis as icons** — Use SVG icons (Heroicons, Lucide, Simple Icons)
- ❌ **Missing cursor:pointer** — All clickable elements must have cursor:pointer
- ❌ **Layout-shifting hovers** — Avoid scale transforms that shift layout
- ❌ **Low contrast text** — Maintain 4.5:1 minimum contrast ratio
- ❌ **Instant state changes** — Always use transitions (150-300ms)
- ❌ **Invisible focus states** — Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
