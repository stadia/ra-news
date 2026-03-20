# Ruby-News 디자인 시스템 가이드

> **생성일:** 2026-02-08
> **최종 업데이트:** 2026-03-19
> **프로젝트:** Ruby-News (루비 AI 뉴스)
> **목적:** 일관된 UI/UX 제공 및 접근성 개선

---

## 목차

1. [현재 디자인 분석](#현재-디자인-분석)
2. [디자인 시스템 개요](#디자인-시스템-개요)
3. [토큰 아키텍처](#토큰-아키텍처)
4. [색상 시스템](#색상-시스템)
5. [Tailwind 시맨틱 클래스](#tailwind-시맨틱-클래스)
6. [타이포그래피](#타이포그래피)
7. [컴포넌트 가이드라인](#컴포넌트-가이드라인)
8. [접근성 체크리스트](#접근성-체크리스트)

---

## 현재 디자인 분석

### 사용 중인 기술
- **Frontend Framework:** Rails 8 + Hotwire (Turbo/Stimulus)
- **CSS Framework:** Tailwind CSS 4.2
- **Component Library:** RubyUI + Phlex
- **Icon Library:** Heroicons (via phlex_icons)
- **Font:** Noto Sans KR (Google Fonts)
- **Design Token System:** CSS Custom Properties + Tailwind `@theme inline`

### 현재 강점
✅ 3-tier 토큰 시스템 (Primitive → Semantic → Component)
✅ 다크/라이트 테마 지원 기반 완비
✅ 시맨틱 토큰 기반 색상 사용 (하드코딩 제거 완료)
✅ Heroicons 사용 (이모지 아님)
✅ 반응형 레이아웃 (Tailwind 기반)
✅ 접근성: Skip Link, ARIA 레이블, prefers-reduced-motion
✅ 한글 폰트 최적화 (Noto Sans KR)

---

## 디자인 시스템 개요

### 디자인 철학
- **다크 모드 우선:** 개발자/기술 커뮤니티 중심 (`.theme-dark` 기본)
- **정보 밀도:** 많은 뉴스를 효율적으로 표시
- **빠른 스캔:** 제목, 요약, 태그를 빠르게 인식
- **접근성:** WCAG 2.1 AA 수준 준수
- **테마 유연성:** 시맨틱 토큰으로 테마 전환 비용 최소화

### 스타일 키워드
```
Bold, Modern, Clean, Professional, Tech-focused, Korean-friendly
```

---

## 토큰 아키텍처

### 3-Tier 구조

```
┌─────────────────────────────────────────────────────┐
│  Tier 1: Primitive Tokens (tokens.css :root)        │
│  --brand-primary, --neutral-700, etc.               │
│  → 절대 색상값, 테마 불변                              │
├─────────────────────────────────────────────────────┤
│  Tier 2: Semantic Tokens (tokens.css per-theme)     │
│  --color-bg-primary, --semantic-link, etc.           │
│  → 용도 기반, 테마별 분기                              │
├─────────────────────────────────────────────────────┤
│  Tier 3: Component Aliases (application.css @theme)  │
│  --color-surface, --color-content, --color-brand     │
│  → Tailwind 클래스로 직접 사용                         │
└─────────────────────────────────────────────────────┘
```

### 파일 구조

| 파일 | 역할 |
|------|------|
| `app/assets/tailwind/tokens.css` | Tier 1 + Tier 2 토큰 정의 |
| `app/assets/tailwind/application.css` | Tier 3 컴포넌트 별칭 (`@theme inline`) |
| `app/assets/tailwind/site.css` | 사이트 전용 스타일 |
| `app/assets/tailwind/pagy-tailwind.css` | 페이지네이션 스타일 |

---

## 색상 시스템

### Tier 1: Primitive Tokens (테마 불변)

```css
/* Brand Colors */
--brand-primary: 34 197 94;        /* green-500 */
--brand-primary-hover: 22 163 74;  /* green-600 */
--brand-primary-light: 74 222 128; /* green-400 */
--brand-primary-dark: 21 128 61;   /* green-700 */
--brand-primary-deep: 22 101 52;   /* green-800 */

/* Neutral Colors (Slate Palette) */
--neutral-50 ~ --neutral-950

/* Status Colors */
--color-success, --color-warning, --color-error, --color-info
```

### Tier 2: Semantic Tokens (테마별 분기)

`.theme-dark` / `.theme-light` 선택자에서 정의:

| 토큰 | Dark 테마 | Light 테마 | 용도 |
|------|-----------|------------|------|
| `--color-bg-primary` | neutral-900 | neutral-50 | Body 배경 |
| `--color-bg-secondary` | neutral-800 | neutral-100 | 카드, 섹션 배경 |
| `--color-bg-tertiary` | neutral-700 | neutral-200 | 입력 필드 |
| `--color-text-primary` | neutral-50 | neutral-950 | 제목, 중요 텍스트 |
| `--color-text-secondary` | neutral-200 | neutral-800 | 본문 텍스트 |
| `--color-text-muted` | neutral-400 | neutral-600 | 보조 텍스트 |
| `--color-text-disabled` | neutral-600 | neutral-400 | 비활성 텍스트 |
| `--color-border` | neutral-700 | neutral-300 | 기본 테두리 |
| `--semantic-link` | brand-primary-light | brand-primary-dark | 링크 |
| `--semantic-accent-text` | brand-primary-light | brand-primary-dark | 강조 텍스트 |
| `--semantic-brand-solid` | brand-primary-dark | brand-primary-dark | 브랜드 배경 |
| `--semantic-danger-solid` | red-600 | red-600 | 위험 배경 |
| `--semantic-danger-text` | red-400 | red-600 | 위험 텍스트 |
| `--semantic-info-solid` | blue-600 | blue-600 | 정보 배경 |

### Tier 3: Tailwind 시맨틱 클래스

`application.css`의 `@theme inline` 블록에서 정의:

```css
@theme inline {
    --color-app: rgb(var(--color-bg-primary));
    --color-surface: rgb(var(--color-bg-secondary));
    --color-surface-muted: rgb(var(--color-bg-tertiary));
    --color-content: rgb(var(--color-text-primary));
    --color-content-secondary: rgb(var(--color-text-secondary));
    --color-content-muted: rgb(var(--color-text-muted));
    --color-content-disabled: rgb(var(--color-text-disabled));
    --color-border-strong: rgb(var(--color-border));
    --color-border-muted: rgb(var(--color-border-light));
    --color-border-subtle: rgb(var(--color-border-dark));
    --color-brand: rgb(var(--brand-primary));
    --color-brand-solid: rgb(var(--semantic-brand-solid));
    --color-brand-solid-hover: rgb(var(--semantic-brand-solid-hover));
    --color-brand-foreground: rgb(255 255 255);
    --color-link: rgb(var(--semantic-link));
    --color-link-hover: rgb(var(--semantic-link-hover));
    --color-accent-text: rgb(var(--semantic-accent-text));
    --color-danger-solid: rgb(var(--semantic-danger-solid));
    --color-danger-solid-hover: rgb(var(--semantic-danger-solid-hover));
    --color-danger-text: rgb(var(--semantic-danger-text));
    --color-info-solid: rgb(var(--semantic-info-solid));
    --color-info-solid-hover: rgb(var(--semantic-info-solid-hover));
    --color-info-text: rgb(var(--semantic-info-text));
    /* ... */
}
```

---

## Tailwind 시맨틱 클래스

### 배경 (Background)

| 시맨틱 클래스 | 용도 | Dark 값 |
|--------------|------|---------|
| `bg-app` | Body/페이지 배경 | slate-900 |
| `bg-surface` | 카드, 섹션 배경 | slate-800 |
| `bg-surface-muted` | 입력 필드, 보조 요소 | slate-700 |
| `bg-surface-elevated` | 모달, 드롭다운 | slate-800 |
| `bg-brand` | 브랜드 배경 (투명도 가능) | green-500 |
| `bg-brand-solid` | 단색 브랜드 배경 (버튼) | green-700 |
| `bg-brand-solid-hover` | 브랜드 버튼 hover | green-800 |
| `bg-danger-solid` | 위험 버튼 | red-600 |
| `bg-info-solid` | 정보 버튼 | blue-600 |

### 텍스트 (Text)

| 시맨틱 클래스 | 용도 | Dark 값 |
|--------------|------|---------|
| `text-content` | 제목, 주요 텍스트 | slate-50 |
| `text-content-secondary` | 본문 텍스트 | slate-200 |
| `text-content-muted` | 보조 텍스트, 메타데이터 | slate-400 |
| `text-content-disabled` | 비활성 텍스트, 구분자 | slate-600 |
| `text-accent-text` | 브랜드 강조 텍스트 | green-400 |
| `text-link-hover` | 링크 hover | green-500 |
| `text-brand-foreground` | 브랜드 배경 위 텍스트 | white |
| `text-danger-text` | 위험/삭제 텍스트 | red-400 |
| `text-info-text` | 정보 텍스트 | blue-500 |

### 테두리 (Border)

| 시맨틱 클래스 | 용도 | Dark 값 |
|--------------|------|---------|
| `border-border-strong` | 기본 테두리 | slate-700 |
| `border-border-muted` | hover, 포커스 테두리 | slate-600 |
| `border-border-subtle` | 미묘한 구분선 | slate-800 |
| `border-brand` | 브랜드 강조 테두리 | green-500 |

### 포커스/링

| 시맨틱 클래스 | 용도 |
|--------------|------|
| `ring-brand` | 브랜드 포커스 링 |
| `ring-offset-app` | 포커스 링 오프셋 배경 |
| `ring-offset-surface` | 카드 위 포커스 링 오프셋 |

---

## 타이포그래피

### 폰트 설정
```css
--font-primary: "Noto Sans KR", sans-serif;
```

### 사용 예시

#### 기사 제목
```ruby
h1(class: "text-3xl md:text-4xl font-bold text-content leading-tight")
```

#### 본문
```ruby
p(class: "text-base text-content-secondary leading-relaxed")
```

#### 메타데이터
```ruby
span(class: "text-sm text-content-muted")
```

#### Prose (마크다운 콘텐츠)
```ruby
div(class: "prose prose-invert prose-lg max-w-none
            prose-headings:text-prose-heading-accent
            prose-strong:text-prose-strong-accent")
```

---

## 컴포넌트 가이드라인

### 1. 버튼

#### Primary (브랜드 액션)
```ruby
class: "px-4 py-2 text-sm font-medium bg-brand-solid hover:bg-brand-solid-hover
        text-brand-foreground rounded-lg transition-colors cursor-pointer"
```

#### Secondary (보조 액션)
```ruby
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-surface
        text-content-secondary rounded-lg transition-colors cursor-pointer"
```

#### Danger (위험/삭제)
```ruby
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-danger-solid
        text-content-secondary hover:text-danger-text rounded-lg transition-colors cursor-pointer"
```

#### Info (정보/수락)
```ruby
class: "px-4 py-2 text-sm font-medium bg-info-solid hover:bg-info-solid-hover
        text-brand-foreground rounded-lg transition-colors cursor-pointer"
```

### 2. 카드

#### 기본 카드
```ruby
render RubyUI::Card.new(class: "bg-surface shadow-md hover:shadow-lg
    transition-shadow overflow-hidden border-border-strong p-3 md:p-6")
```

#### 프로필 카드 (투명 배경)
```ruby
render RubyUI::Card.new(class: "bg-app/40 border-border-subtle
    rounded-2xl overflow-hidden shadow-2xl")
```

#### 리스트 아이템
```ruby
div(class: "flex items-center gap-4 px-4 py-3 bg-app/40
    border border-border-subtle rounded-xl hover:border-border-strong transition-colors")
```

### 3. 입력 필드

```ruby
render RubyUI::Input.new(
  class: "bg-surface-muted border-border-muted text-content placeholder:text-content-muted"
)
```

### 4. 네비게이션

```ruby
nav(class: "bg-surface border-b border-border-strong border-t-4 border-t-brand")
```

#### 네비게이션 링크
```ruby
a(class: "text-content-secondary hover:text-content transition-colors")
```

#### 브랜드 강조 텍스트
```ruby
span(class: "text-accent-text")
```

### 5. 아바타 (RubyUI)

```ruby
render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
  render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground font-bold") do
    plain initials
  end
end
```

### 6. 뱃지 (RubyUI)

```ruby
render RubyUI::Badge.new(variant: :green) { "팔로잉" }
render RubyUI::Badge.new(variant: :amber) { "요청 중" }
```

### 7. 보조 텍스트 / 상태 메시지

```ruby
span(class: "text-content-muted text-sm") { "내 계정입니다." }
p(class: "text-content-muted mt-4") { "이 계정은 더 이상 존재하지 않습니다." }
```

### 8. 코드 블록 (인라인)

```ruby
code(class: "ml-1 bg-surface px-1.5 py-0.5 rounded text-content-secondary text-xs")
```

---

## 접근성 체크리스트

### 필수 요소

#### 1. 키보드 네비게이션
```css
/* 통합 포커스 유틸리티 클래스 (tokens.css) */
.focus-visible-ring {
    @apply focus-visible:outline-none focus-visible:ring-2
           focus-visible:ring-brand focus-visible:ring-offset-2
           focus-visible:ring-offset-app;
}
```

#### 2. Skip Link
```ruby
a(
  href: "#main-content",
  class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4
          focus:z-50 focus:px-4 focus:py-2 focus:bg-brand-solid
          focus:text-brand-foreground focus:rounded-lg focus:shadow-lg"
) { "본문으로 건너뛰기" }
```

#### 3. 모션 감소
```css
/* tokens.css에 포함 */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

#### 4. 색상 대비 (Dark 테마 기준)
```
✅ text-content (slate-50) on bg-app (slate-900): 18.9:1
✅ text-content-secondary (slate-200) on bg-app (slate-900): 14.1:1
✅ text-accent-text (green-400) on bg-app (slate-900): 8.2:1
✅ text-content-muted (slate-400) on bg-app (slate-900): 5.9:1
```

#### 5. ARIA 레이블
```ruby
nav(aria_label: "주 네비게이션")
label(aria_label: "메뉴 열기/닫기")
```

---

## 마이그레이션 가이드: 하드코딩 → 시맨틱 토큰

### ❌ 사용 금지 (하드코딩)

```css
bg-gray-*          /* gray 팔레트 사용 금지 */
bg-slate-800       /* 직접 팔레트 참조 금지 */
text-green-400     /* 직접 팔레트 참조 금지 */
border-slate-700   /* 직접 팔레트 참조 금지 */
text-white         /* 시맨틱 토큰 사용 */
```

### ✅ 사용 필수 (시맨틱 토큰)

| 하드코딩 (Before) | 시맨틱 토큰 (After) |
|---|---|
| `bg-gray-800`, `bg-slate-800` | `bg-surface` |
| `bg-slate-900` | `bg-app` |
| `text-white`, `text-gray-100`, `text-slate-50` | `text-content` |
| `text-gray-300`, `text-slate-200` | `text-content-secondary` |
| `text-gray-400`, `text-slate-400` | `text-content-muted` |
| `text-gray-500`, `text-slate-600` | `text-content-disabled` |
| `border-gray-700`, `border-slate-700` | `border-border-strong` |
| `border-slate-600` | `border-border-muted` |
| `border-slate-800` | `border-border-subtle` |
| `text-green-400` | `text-accent-text` |
| `bg-green-600 hover:bg-green-500` | `bg-brand-solid hover:bg-brand-solid-hover` |
| `bg-blue-600 hover:bg-blue-500` | `bg-info-solid hover:bg-info-solid-hover` |
| `bg-slate-700 hover:bg-red-900` | `bg-surface-muted hover:bg-danger-solid` |
| `text-slate-300 hover:text-red-300` | `text-content-secondary hover:text-danger-text` |
| `ring-green-500` | `ring-brand` |
| `ring-offset-slate-900` | `ring-offset-app` |

> **참고:** `madmin/` (어드민) 뷰는 별도 레이아웃을 사용하므로 시맨틱 토큰 적용 대상에서 제외합니다.

---

## 참고 자료

### 접근성
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Tailwind CSS
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

### 컴포넌트
- [Phlex](https://www.phlex.fun/)
- [RubyUI](https://rubyui.com/)

### 디자인 시스템 참고
- [Shopify Polaris](https://polaris.shopify.com/)
- [GitHub Primer](https://primer.style/)

---

**마지막 업데이트:** 2026-03-19
