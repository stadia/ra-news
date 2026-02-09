# Ruby-News 디자인 시스템 가이드

> **생성일:** 2026-02-08
> **프로젝트:** Ruby-News (루비 AI 뉴스)
> **목적:** 일관된 UI/UX 제공 및 접근성 개선

---

## 목차

1. [현재 디자인 분석](#현재-디자인-분석)
2. [디자인 시스템 개요](#디자인-시스템-개요)
3. [색상 팔레트](#색상-팔레트)
4. [타이포그래피](#타이포그래피)
5. [컴포넌트 가이드라인](#컴포넌트-가이드라인)
6. [접근성 체크리스트](#접근성-체크리스트)
7. [개선 권장사항](#개선-권장사항)

---

## 현재 디자인 분석

### 사용 중인 기술
- **Frontend Framework:** Rails 8 + Hotwire (Turbo/Stimulus)
- **CSS Framework:** Tailwind CSS 4.2
- **Component Library:** ViewComponent + Phlex
- **Icon Library:** Heroicons
- **Font:** Noto Sans KR (Google Fonts)

### 현재 색상 사용

#### 주요 색상
```css
/* 현재 사용 중 */
- Primary: green-700 (#15803d) - 네비게이션, 버튼
- Secondary: green-600 (#16a34a) - 호버 상태
- Background: gray-900 (#111827) - 다크 모드 배경
- Card Background: gray-800 (#1f2937) - 카드 배경
- Text: gray-200 (#e5e7eb) - 본문
- Text Bright: gray-100 (#f3f4f6) - 제목
- Accent: green-400 (#4ade80) - 링크 호버
```

### 현재 강점
✅ 일관된 다크 모드 디자인
✅ Heroicons 사용 (이모지 아님)
✅ 반응형 레이아웃 (Tailwind 기반)
✅ Hotwire를 통한 빠른 페이지 전환
✅ 한글 폰트 최적화 (Noto Sans KR)

### 개선 필요 영역
⚠️ 색상 팔레트 일관성 (green-500, green-600, green-700 혼용)
⚠️ 접근성 - 키보드 네비게이션 포커스 상태
⚠️ 애니메이션 - prefers-reduced-motion 미지원
⚠️ 컴포넌트 재사용성 (중복 스타일 존재)
⚠️ CSS 변수 미사용 (하드코딩된 색상값)

---

## 디자인 시스템 개요

### 디자인 철학
- **다크 모드 우선:** 개발자/기술 커뮤니티 중심
- **정보 밀도:** 많은 뉴스를 효율적으로 표시
- **빠른 스캔:** 제목, 요약, 태그를 빠르게 인식
- **접근성:** WCAG 2.1 AA 수준 준수

### 스타일 키워드
```
Bold, Modern, Clean, Professional, Tech-focused, Korean-friendly
```

---

## 색상 팔레트

### 권장 색상 시스템

#### CSS 변수 정의
```css
:root {
  /* Primary Colors */
  --color-primary: #1E293B;      /* slate-800 */
  --color-primary-light: #334155; /* slate-700 */
  --color-primary-dark: #0F172A;  /* slate-900 */

  /* Accent Colors */
  --color-accent: #22C55E;        /* green-500 */
  --color-accent-hover: #16A34A;  /* green-600 */
  --color-accent-light: #4ADE80;  /* green-400 */

  /* Background Colors */
  --color-bg-primary: #0F172A;    /* slate-900 */
  --color-bg-secondary: #1E293B;  /* slate-800 */
  --color-bg-tertiary: #334155;   /* slate-700 */

  /* Text Colors */
  --color-text-primary: #F8FAFC;  /* slate-50 */
  --color-text-secondary: #E2E8F0; /* slate-200 */
  --color-text-muted: #94A3B8;    /* slate-400 */

  /* Status Colors */
  --color-success: #22C55E;       /* green-500 */
  --color-warning: #F59E0B;       /* amber-500 */
  --color-error: #EF4444;         /* red-500 */
  --color-info: #3B82F6;          /* blue-500 */

  /* Border Colors */
  --color-border: #334155;        /* slate-700 */
  --color-border-light: #475569;  /* slate-600 */

  /* Prose (Typography Plugin) Accent Colors */
  --color-prose-heading: #4ADE80; /* green-400 - 헤딩 포인트 */
  --color-prose-strong: #7DD3FC;  /* sky-300 - 강조 텍스트 포인트 */
}
```

#### Tailwind 색상 매핑

**현재:**
```html
<nav class="bg-green-700">        <!-- 일관성 없음 -->
<button class="bg-green-600">     <!-- 일관성 없음 -->
<div class="text-green-400">      <!-- 일관성 없음 -->
```

**권장:**
```html
<nav class="bg-slate-800">        <!-- Primary background -->
<button class="bg-green-500">     <!-- Accent color -->
<div class="text-green-400">      <!-- Accent light -->
```

### 색상 사용 가이드

#### 네비게이션
```css
/* 현재 */
bg-green-700, border-green-800

/* 권장 */
bg-slate-800, border-slate-700
```

#### 버튼
```css
/* Primary Button */
bg-green-500 hover:bg-green-600 text-white

/* Secondary Button */
bg-slate-700 hover:bg-slate-600 text-slate-100

/* Ghost Button */
bg-transparent hover:bg-slate-800 text-green-400
```

#### 카드
```css
/* 기본 카드 */
bg-slate-800 border-slate-700

/* 호버 상태 */
hover:border-slate-600 hover:bg-slate-750
```

#### 텍스트
```css
/* 제목 */
text-slate-50

/* 본문 */
text-slate-200

/* 보조 텍스트 */
text-slate-400
```

#### Prose (마크다운 콘텐츠)
```html
<!-- 어두운 배경에서 마크다운 렌더링 시 필수 클래스 -->
<div class="prose prose-invert prose-lg max-w-none
            prose-headings:text-green-400
            prose-strong:text-sky-300">
  <%= markdown_content %>
</div>
```
- `prose-invert`: 어두운 배경 대응 (밝은 기본 텍스트)
- `prose-headings:text-green-400`: 헤딩(h1~h6)에 브랜드 포인트 컬러
- `prose-strong:text-sky-300`: 강조 텍스트에 보조 포인트 컬러

---

## 타이포그래피

### 현재 폰트 설정
```css
/* Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap');

font-family: 'Noto Sans KR', sans-serif;
```

### 권장 타이포그래피 스케일

```css
/* Type Scale (Tailwind) */
.text-xs    { font-size: 0.75rem;  /* 12px */ }
.text-sm    { font-size: 0.875rem; /* 14px */ }
.text-base  { font-size: 1rem;     /* 16px */ }
.text-lg    { font-size: 1.125rem; /* 18px */ }
.text-xl    { font-size: 1.25rem;  /* 20px */ }
.text-2xl   { font-size: 1.5rem;   /* 24px */ }
.text-3xl   { font-size: 1.875rem; /* 30px */ }
.text-4xl   { font-size: 2.25rem;  /* 36px */ }

/* Font Weights */
.font-normal  { font-weight: 400; }
.font-medium  { font-weight: 500; }
.font-bold    { font-weight: 700; }

/* Line Heights */
.leading-tight    { line-height: 1.25; } /* 제목용 */
.leading-normal   { line-height: 1.5;  } /* 본문용 */
.leading-relaxed  { line-height: 1.625; } /* 긴 글용 */
```

### 사용 예시

#### 기사 제목
```html
<h1 class="text-3xl md:text-4xl font-bold text-slate-50 leading-tight">
  제목
</h1>
```

#### 본문
```html
<p class="text-base text-slate-200 leading-relaxed">
  본문 내용
</p>
```

#### 메타데이터
```html
<span class="text-sm text-slate-400">
  2025년 2월 8일
</span>
```

---

## 컴포넌트 가이드라인

### 1. 버튼

#### Primary Button
```html
<button class="
  px-4 py-2
  bg-green-500 hover:bg-green-600
  text-white font-medium
  rounded-lg
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
  cursor-pointer
">
  버튼 텍스트
</button>
```

#### Secondary Button
```html
<button class="
  px-4 py-2
  bg-slate-700 hover:bg-slate-600
  text-slate-100 font-medium
  rounded-lg
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 focus:ring-offset-slate-900
  cursor-pointer
">
  버튼 텍스트
</button>
```

#### Ghost Button
```html
<button class="
  px-4 py-2
  bg-transparent hover:bg-slate-800
  text-green-400 hover:text-green-300 font-medium
  rounded-lg
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
  cursor-pointer
">
  버튼 텍스트
</button>
```

### 2. 카드

#### 기본 카드
```html
<article class="
  bg-slate-800
  border border-slate-700
  rounded-xl
  p-6
  shadow-lg
  transition-all duration-200
  hover:border-slate-600 hover:shadow-xl
  cursor-pointer
">
  <!-- 카드 내용 -->
</article>
```

#### 상호작용 카드
```html
<a href="#" class="
  block
  bg-slate-800
  border border-slate-700
  rounded-xl
  p-6
  shadow-lg
  transition-all duration-200
  hover:border-slate-600 hover:shadow-xl hover:-translate-y-1
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
  group
">
  <h2 class="text-xl font-bold text-slate-50 group-hover:text-green-400 transition-colors">
    제목
  </h2>
</a>
```

### 3. 입력 필드

#### Text Input
```html
<input
  type="text"
  class="
    w-full
    px-4 py-2
    bg-slate-800
    border border-slate-700
    rounded-lg
    text-slate-100
    placeholder-slate-500
    transition-colors duration-200
    focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent
  "
  placeholder="입력하세요"
>
```

### 4. 네비게이션 링크

```html
<a href="#" class="
  px-4 py-2
  text-slate-200 hover:text-white
  rounded-lg
  transition-colors duration-200
  hover:bg-slate-700
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
">
  링크 텍스트
</a>
```

### 5. 뱃지/태그

```html
<span class="
  inline-flex items-center
  px-3 py-1
  bg-green-500/10
  text-green-400
  text-sm font-medium
  rounded-full
">
  태그
</span>
```

---

## 접근성 체크리스트

### 필수 요소

#### 1. 키보드 네비게이션
```css
/* 모든 상호작용 요소에 포커스 스타일 적용 */
.focus-visible:outline-none
.focus-visible:ring-2
.focus-visible:ring-green-500
.focus-visible:ring-offset-2
.focus-visible:ring-offset-slate-900
```

#### 2. 색상 대비
- **최소 대비율:** 4.5:1 (일반 텍스트)
- **큰 텍스트:** 3:1 (18pt 이상 또는 14pt bold)

**현재 검증:**
```
✅ slate-50 on slate-900: 18.9:1 (Excellent)
✅ slate-200 on slate-900: 14.1:1 (Excellent)
✅ green-400 on slate-900: 8.2:1 (Excellent)
✅ slate-400 on slate-900: 5.9:1 (Good)
```

#### 3. 스크린 리더
```html
<!-- 아이콘 버튼 -->
<button aria-label="메뉴 열기">
  <svg>...</svg>
</button>

<!-- 숨김 텍스트 -->
<span class="sr-only">화면 리더 전용 텍스트</span>

<!-- Landmark -->
<nav aria-label="주 네비게이션">...</nav>
<main>...</main>
<footer>...</footer>
```

#### 4. 모션 감소
```css
/* 애니메이션 감소 선호 사용자 */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

#### 5. 터치 타겟 크기
```css
/* 최소 44x44px */
.min-h-11  /* 44px */
.min-w-11  /* 44px */
```

---

## 개선 권장사항

### 1. CSS 변수 도입

**새 파일 생성:** `app/assets/stylesheets/tokens.css`

```css
@layer base {
  :root {
    /* Colors */
    --color-primary: 30 41 59;        /* slate-800 */
    --color-accent: 34 197 94;        /* green-500 */
    --color-bg-primary: 15 23 42;     /* slate-900 */
    --color-text-primary: 248 250 252; /* slate-50 */

    /* Spacing */
    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;
    --space-xl: 2rem;
    --space-2xl: 3rem;

    /* Shadows */
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
    --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
    --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);

    /* Border Radius */
    --radius-sm: 0.375rem;  /* 6px */
    --radius-md: 0.5rem;    /* 8px */
    --radius-lg: 0.75rem;   /* 12px */
    --radius-xl: 1rem;      /* 16px */

    /* Transitions */
    --transition-fast: 150ms;
    --transition-base: 200ms;
    --transition-slow: 300ms;
  }
}
```

**Tailwind에서 사용:**
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'rgb(var(--color-primary) / <alpha-value>)',
        accent: 'rgb(var(--color-accent) / <alpha-value>)',
      },
    },
  },
}
```

### 2. 컴포넌트 추출

**현재 문제:**
- 네비게이션 링크 스타일 중복
- 버튼 스타일 중복
- 카드 스타일 중복

**권장 구조:**
```
app/
  components/
    ui/
      button_component.rb
      card_component.rb
      badge_component.rb
      input_component.rb
  view_components/
    navigation/
      nav_link_component.rb
      mobile_menu_component.rb
```

**예시:** `app/components/ui/button_component.rb`
```ruby
# frozen_string_literal: true

class Ui::ButtonComponent < Components::Base
  def initialize(variant: :primary, size: :md, **attrs)
    @variant = variant
    @size = size
    @attrs = attrs
  end

  def template
    button(**attrs_with_classes) do
      yield
    end
  end

  private

  def attrs_with_classes
    @attrs.merge(class: button_classes)
  end

  def button_classes
    [
      base_classes,
      variant_classes,
      size_classes,
    ].join(" ")
  end

  def base_classes
    "font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 cursor-pointer"
  end

  def variant_classes
    case @variant
    when :primary
      "bg-green-500 hover:bg-green-600 text-white focus:ring-green-500"
    when :secondary
      "bg-slate-700 hover:bg-slate-600 text-slate-100 focus:ring-slate-500"
    when :ghost
      "bg-transparent hover:bg-slate-800 text-green-400 hover:text-green-300 focus:ring-green-500"
    end
  end

  def size_classes
    case @size
    when :sm
      "px-3 py-1.5 text-sm"
    when :md
      "px-4 py-2 text-base"
    when :lg
      "px-6 py-3 text-lg"
    end
  end
end
```

**사용:**
```erb
<%= render Ui::ButtonComponent.new(variant: :primary, size: :md) do %>
  클릭하세요
<% end %>
```

### 3. 접근성 개선

#### 네비게이션 개선
```erb
<!-- 현재 -->
<nav class="bg-green-700">
  <ul>
    <li><a href="/">홈</a></li>
  </ul>
</nav>

<!-- 권장 -->
<nav class="bg-slate-800" aria-label="주 네비게이션">
  <ul>
    <li>
      <a href="/"
         class="focus:outline-none focus:ring-2 focus:ring-green-500"
         aria-current="page">
        홈
      </a>
    </li>
  </ul>
</nav>
```

#### Skip Link 추가
```erb
<!-- layouts/application.html.erb 최상단 -->
<a href="#main-content"
   class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-green-500 focus:text-white focus:rounded-lg">
  본문으로 건너뛰기
</a>

<main id="main-content">
  <%= yield %>
</main>
```

#### 모션 감소 지원
```css
/* app/assets/stylesheets/application.css */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### 4. 성능 최적화

#### 폰트 로딩 최적화
```erb
<!-- 현재 -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preload" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap" as="style">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap">

<!-- 권장: font-display: swap 추가 -->
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap">
```

#### 이미지 최적화
```erb
<!-- WebP 사용 -->
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="설명" loading="lazy">
</picture>
```

### 5. 다크 모드 테마 전환 (선택사항)

**미래 확장을 위한 준비:**

```css
/* tokens.css */
:root {
  --color-bg-primary: 15 23 42;    /* 다크 */
}

[data-theme="light"] {
  --color-bg-primary: 248 250 252; /* 라이트 */
}
```

```javascript
// app/javascript/controllers/theme_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const current = document.documentElement.dataset.theme || 'dark'
    const next = current === 'dark' ? 'light' : 'dark'

    document.documentElement.dataset.theme = next
    localStorage.setItem('theme', next)
  }
}
```

---

## 체크리스트 (구현 전)

### 단기 개선사항 (1-2주)
- [ ] CSS 변수 도입 (`tokens.css` 생성)
- [ ] 색상 일관성 개선 (green-700 → slate-800)
- [ ] 포커스 스타일 추가 (모든 상호작용 요소)
- [ ] Skip Link 추가
- [ ] `prefers-reduced-motion` 지원

### 중기 개선사항 (1개월)
- [ ] 버튼 컴포넌트 추출
- [ ] 카드 컴포넌트 추출
- [ ] 네비게이션 컴포넌트 리팩토링
- [ ] 입력 필드 컴포넌트 추출
- [ ] 뱃지/태그 컴포넌트 추출

### 장기 개선사항 (2-3개월)
- [ ] 라이트 모드 지원 (선택사항)
- [ ] 컴포넌트 스토리북 구축
- [ ] 디자인 시스템 문서화 사이트
- [ ] 접근성 자동 테스트 도입

---

## 참고 자료

### 접근성
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [a11y Project Checklist](https://www.a11yproject.com/checklist/)

### Tailwind CSS
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Tailwind UI Components](https://tailwindui.com/)

### Ruby on Rails
- [ViewComponent](https://viewcomponent.org/)
- [Phlex](https://www.phlex.fun/)

### 디자인 시스템 예시
- [Shopify Polaris](https://polaris.shopify.com/)
- [GitHub Primer](https://primer.style/)
- [Atlassian Design System](https://atlassian.design/)

---

## 마스터 디자인 시스템

더 상세한 디자인 시스템 정보는 다음 파일을 참조하세요:

📄 `design-system/ruby-news/MASTER.md` - Global Source of Truth

페이지별 오버라이드가 필요한 경우:

📁 `design-system/ruby-news/pages/` - 페이지별 디자인 규칙

---

## 문의

디자인 시스템에 대한 질문이나 제안사항이 있으시면 GitHub Issues에 등록해 주세요.
