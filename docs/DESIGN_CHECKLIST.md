# 디자인 시스템 체크리스트

> **빠른 참조:** 새로운 UI 컴포넌트나 페이지를 만들 때 사용하는 체크리스트
> **최종 업데이트:** 2026-03-19

---

## 색상 사용 가이드

### ✅ 사용해야 할 시맨틱 클래스

```css
/* Background */
bg-app              /* Body/페이지 배경 */
bg-surface           /* 카드, 섹션 배경 */
bg-surface-muted     /* 입력 필드, 보조 버튼 */
bg-surface-elevated  /* 모달, 드롭다운 */

/* Text */
text-content           /* 제목, 주요 텍스트 */
text-content-secondary /* 본문 텍스트 */
text-content-muted     /* 보조 텍스트, 메타데이터 */
text-content-disabled  /* 비활성 텍스트, 구분자 */
text-accent-text       /* 브랜드 강조 텍스트 */

/* Accent/CTA */
bg-brand-solid hover:bg-brand-solid-hover  /* Primary 버튼 */
bg-info-solid hover:bg-info-solid-hover    /* Info 버튼 */
bg-danger-solid hover:bg-danger-solid-hover /* Danger 버튼 */
text-brand-foreground                       /* 버튼 위 텍스트 */

/* Border */
border-border-strong  /* 기본 테두리 */
border-border-muted   /* 호버/포커스 테두리 */
border-border-subtle  /* 미묘한 구분선 */
border-brand          /* 브랜드 강조 테두리 */

/* Focus */
ring-brand            /* 포커스 링 */
ring-offset-app       /* 포커스 링 오프셋 (페이지 배경) */
ring-offset-surface   /* 포커스 링 오프셋 (카드 배경) */
```

### ❌ 사용하지 말아야 할 클래스

```css
bg-gray-*          /* gray 팔레트 직접 사용 금지 → bg-surface 등 사용 */
bg-slate-*         /* slate 팔레트 직접 사용 금지 → bg-app/bg-surface 등 사용 */
text-white         /* → text-content 사용 */
text-green-*       /* → text-accent-text, text-link-hover 등 사용 */
text-red-*         /* → text-danger-text 사용 */
text-blue-*        /* → text-info-text 사용 */
bg-green-*         /* → bg-brand-solid 등 사용 */
bg-red-*           /* → bg-danger-solid 등 사용 */
bg-blue-*          /* → bg-info-solid 등 사용 */
border-gray-*      /* → border-border-strong 등 사용 */
border-slate-*     /* → border-border-strong 등 사용 */
ring-green-*       /* → ring-brand 사용 */
ring-offset-slate-*/* → ring-offset-app 사용 */
```

> **예외:** `madmin/` (어드민) 뷰는 별도 레이아웃이므로 적용 대상 아님

---

## 컴포넌트 체크리스트

### 버튼

```ruby
# ✅ Good - Primary 버튼
class: "px-4 py-2 text-sm font-medium bg-brand-solid hover:bg-brand-solid-hover
        text-brand-foreground rounded-lg transition-colors cursor-pointer"

# ✅ Good - Secondary 버튼
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-surface
        text-content-secondary rounded-lg transition-colors cursor-pointer"

# ✅ Good - Danger 버튼 (hover 시 위험 표시)
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-danger-solid
        text-content-secondary hover:text-danger-text rounded-lg
        border border-border-muted transition-colors cursor-pointer"

# ❌ Bad
class: "bg-green-700 hover:bg-green-600 text-white"
```

**필수 속성:**
- [ ] `cursor-pointer`
- [ ] `transition-colors`
- [ ] hover 상태 (`hover:bg-*`)
- [ ] 시맨틱 색상 클래스 사용

### 카드

```ruby
# ✅ Good - RubyUI Card
render RubyUI::Card.new(class: "bg-surface shadow-md hover:shadow-lg
    transition-shadow overflow-hidden border-border-strong p-3 md:p-6")

# ✅ Good - 투명 프로필 카드
render RubyUI::Card.new(class: "bg-app/40 border-border-subtle
    rounded-2xl overflow-hidden shadow-2xl")

# ❌ Bad
class: "bg-gray-800 border border-gray-700"
```

**필수 속성:**
- [ ] `bg-surface` 또는 `bg-app/40` (카드 유형에 따라)
- [ ] `border-border-strong` 또는 `border-border-subtle`
- [ ] `rounded-xl` 또는 `rounded-2xl`
- [ ] 적절한 shadow

### 링크

```ruby
# ✅ Good
class: "text-content-secondary hover:text-content transition-colors"

# ✅ Good - 브랜드 링크
class: "text-content hover:text-link-hover transition-colors"

# ❌ Bad
class: "text-gray-200 hover:text-white"
```

**필수 속성:**
- [ ] 시맨틱 텍스트 색상
- [ ] hover 상태
- [ ] `transition-colors`

### 입력 필드

```ruby
# ✅ Good
class: "bg-surface-muted border-border-muted text-content placeholder:text-content-muted"

# ❌ Bad
class: "bg-slate-700 border-slate-600 text-slate-100"
```

**필수 속성:**
- [ ] `bg-surface-muted`
- [ ] `border-border-muted`
- [ ] `text-content`
- [ ] `placeholder:text-content-muted`

### 아바타 폴백

```ruby
# ✅ Good
render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground font-bold")

# ❌ Bad
class: "bg-slate-600 text-white"
```

---

## 접근성 체크리스트

### 키보드 네비게이션

**모든 상호작용 요소:**
- [ ] Tab으로 포커스 가능
- [ ] Enter/Space로 활성화 가능
- [ ] 포커스 스타일 시각적으로 명확
- [ ] 논리적 Tab 순서

**포커스 스타일 (통합 유틸리티):**
```css
.focus-visible-ring {
    @apply focus-visible:outline-none focus-visible:ring-2
           focus-visible:ring-brand focus-visible:ring-offset-2
           focus-visible:ring-offset-app;
}
```

### ARIA 레이블

**필수 ARIA 속성:**
- [ ] 아이콘 버튼: `aria-label="설명"`
- [ ] 네비게이션: `aria-label="주 네비게이션"`
- [ ] 검색 폼: `role="search"`, `aria-label="검색"`
- [ ] 현재 페이지: `aria-current="page"`
- [ ] 랜드마크: `<nav>`, `<main>`, `<footer>` 사용

### 색상 대비

**최소 대비율:**
- 일반 텍스트: **4.5:1**
- 큰 텍스트 (18pt+ 또는 14pt bold): **3:1**

**검증된 조합 (Dark 테마 기준):**
```
✅ text-content on bg-app:            18.9:1
✅ text-content-secondary on bg-app:  14.1:1
✅ text-accent-text on bg-app:        8.2:1
✅ text-content-muted on bg-app:      5.9:1
```

### 모션 접근성

**prefers-reduced-motion 지원:** `tokens.css`에 포함 (별도 작업 불필요)

---

## 반응형 디자인 체크리스트

### 브레이크포인트

```css
/* Mobile First */
sm:  640px    /* Tailwind sm */
md:  768px    /* 태블릿 */
lg:  1024px   /* 데스크톱 */
xl:  1280px   /* 대형 데스크톱 */
2xl: 1536px   /* 초대형 */
```

### 테스트 해상도

- [ ] 375px (iPhone SE)
- [ ] 768px (iPad 세로)
- [ ] 1024px (iPad 가로, 작은 노트북)
- [ ] 1440px (일반 데스크톱)

---

## 코드 리뷰 체크리스트

### Pull Request 전

**코드 품질:**
- [ ] 하드코딩된 색상 없음 (시맨틱 토큰 사용)
- [ ] `bg-gray-*`, `bg-slate-*`, `text-white` 등 직접 팔레트 참조 없음
- [ ] 중복 스타일 없음 (RubyUI 컴포넌트 재사용)
- [ ] ARIA 레이블 적절히 사용

**시각적 검토:**
- [ ] 모든 페이지/컴포넌트 브라우저에서 확인
- [ ] 375px, 768px, 1024px, 1440px 테스트

---

## 빠른 참조: 변환 테이블

| 하드코딩 | 시맨틱 토큰 |
|---|---|
| `bg-slate-900` | `bg-app` |
| `bg-slate-800`, `bg-gray-800` | `bg-surface` |
| `bg-slate-700` | `bg-surface-muted` |
| `text-white`, `text-slate-50`, `text-gray-100` | `text-content` |
| `text-slate-200`, `text-gray-300` | `text-content-secondary` |
| `text-slate-400`, `text-gray-400` | `text-content-muted` |
| `text-slate-600`, `text-gray-500` | `text-content-disabled` |
| `text-green-400` | `text-accent-text` |
| `border-slate-700`, `border-gray-700` | `border-border-strong` |
| `border-slate-600` | `border-border-muted` |
| `border-slate-800` | `border-border-subtle` |
| `bg-green-600` | `bg-brand-solid` |
| `bg-blue-600` | `bg-info-solid` |
| `bg-red-600` | `bg-danger-solid` |
| `ring-green-500` | `ring-brand` |
| `ring-offset-slate-900` | `ring-offset-app` |

---

## 참고 문서

- [전체 디자인 시스템 가이드](./DESIGN_SYSTEM.md)
- [개선 히스토리](./DESIGN_IMPROVEMENTS.md)
- [코드 컨벤션](../AGENTS.md)

---

**마지막 업데이트:** 2026-03-19
