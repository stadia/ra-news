# 디자인 시스템 개선 액션 플랜

> **생성일:** 2026-02-08
> **우선순위:** High
> **예상 소요 시간:** 2-4주

---

## 개요

Ruby-News 프로젝트의 디자인 시스템을 체계화하고 일관성을 개선하기 위한 구체적인 액션 플랜입니다.

---

## 현재 상태 분석

### 1. 색상 사용 현황

#### 문제점
```erb
<!-- 일관성 없는 green 계열 사용 -->
app/views/layouts/application.html.erb:
  - bg-green-700    (네비게이션 배경)
  - bg-green-600    (모바일 메뉴 배경)
  - bg-green-500    (로딩 스피너 테두리)
  - text-green-400  (링크 호버)
  - text-green-300  (결론 섹션 제목)

<!-- 일관성 없는 gray 계열 사용 -->
  - bg-gray-900     (body 배경)
  - bg-gray-800     (카드 배경)
  - bg-gray-700     (입력 필드 배경)
  - text-gray-200   (본문)
  - text-gray-100   (제목)
```

#### 권장 변경사항
```erb
<!-- Slate 계열로 통일 -->
- bg-slate-900     (body 배경)
- bg-slate-800     (카드 배경)
- bg-slate-700     (입력 필드 배경)
- text-slate-200   (본문)
- text-slate-50    (제목)

<!-- Green 계열 정리 -->
- bg-green-500     (Primary CTA)
- bg-green-600     (Primary CTA Hover)
- text-green-400   (링크, 아이콘)
```

### 2. 접근성 문제

#### 키보드 네비게이션
```erb
<!-- 현재: 포커스 스타일 불완전 -->
<label class="... hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500">

<!-- 문제점 -->
- focus:ring-offset 누락 (다크 배경에서 포커스 링이 보이지 않음)
- 일부 링크에 포커스 스타일 없음
```

#### 모션 접근성
```css
/* 현재: prefers-reduced-motion 지원 없음 */
.animate-spin       /* 로딩 스피너 */
.transition-all     /* 카드 호버 */
```

### 3. daisyUI 활용 미비

프로젝트에 daisyUI v5가 설치되어 있으나, 일부에서만 `btn` 클래스를 사용하고 나머지는 Tailwind를 직접 사용하여 일관성이 떨어짐.

#### 현재 상태
- `ApplicationHelper`에 `btn_class`, `btn_link_to` 헬퍼 존재 (daisyUI `btn` 기반)
- Madmin 뷰에서 `btn btn-primary`, `btn btn-secondary`, `btn btn-danger` 사용
- 프론트엔드 뷰에서는 Tailwind 직접 사용이 혼재

### 4. 컴포넌트 중복

#### 버튼 스타일 중복
```erb
<!-- 패턴 1: daisyUI (Madmin) -->
class="btn btn-primary"
class="btn btn-danger bg-red-600 text-white rounded px-4 py-2 hover:bg-red-700"

<!-- 패턴 2: Tailwind 직접 사용 -->
class="px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-lg ..."

<!-- 패턴 3: 네비게이션 링크 -->
class="py-3 px-4 text-gray-100 rounded-sm md:p-0 min-h-11 ..."
```

---

## 개선 계획

### Phase 1: CSS 변수 도입 (Week 1)

#### 1.1. 토큰 파일 생성

**파일:** `app/assets/stylesheets/tokens.css`

```css
@layer base {
  :root {
    /* Brand Colors */
    --brand-primary: 34 197 94;        /* green-500 */
    --brand-primary-hover: 22 163 74;  /* green-600 */
    --brand-primary-light: 74 222 128; /* green-400 */

    /* Neutral Colors (Slate) */
    --neutral-50: 248 250 252;
    --neutral-100: 241 245 249;
    --neutral-200: 226 232 240;
    --neutral-300: 203 213 225;
    --neutral-400: 148 163 184;
    --neutral-500: 100 116 139;
    --neutral-600: 71 85 105;
    --neutral-700: 51 65 85;
    --neutral-800: 30 41 59;
    --neutral-900: 15 23 42;
    --neutral-950: 2 6 23;

    /* Semantic Colors */
    --color-bg-primary: var(--neutral-900);
    --color-bg-secondary: var(--neutral-800);
    --color-bg-tertiary: var(--neutral-700);

    --color-text-primary: var(--neutral-50);
    --color-text-secondary: var(--neutral-200);
    --color-text-muted: var(--neutral-400);

    --color-border: var(--neutral-700);
    --color-border-light: var(--neutral-600);

    /* Status Colors */
    --color-success: var(--brand-primary);
    --color-warning: 245 158 11;  /* amber-500 */
    --color-error: 239 68 68;     /* red-500 */
    --color-info: 59 130 246;     /* blue-500 */

    /* Spacing */
    --space-xs: 0.25rem;    /* 4px */
    --space-sm: 0.5rem;     /* 8px */
    --space-md: 1rem;       /* 16px */
    --space-lg: 1.5rem;     /* 24px */
    --space-xl: 2rem;       /* 32px */
    --space-2xl: 3rem;      /* 48px */
    --space-3xl: 4rem;      /* 64px */

    /* Border Radius */
    --radius-sm: 0.375rem;  /* 6px */
    --radius-md: 0.5rem;    /* 8px */
    --radius-lg: 0.75rem;   /* 12px */
    --radius-xl: 1rem;      /* 16px */
    --radius-2xl: 1.5rem;   /* 24px */

    /* Shadows */
    --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
    --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
    --shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);

    /* Transitions */
    --transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
    --transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
    --transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);

    /* Z-Index Scale */
    --z-dropdown: 1000;
    --z-sticky: 1020;
    --z-fixed: 1030;
    --z-modal-backdrop: 1040;
    --z-modal: 1050;
    --z-popover: 1060;
    --z-tooltip: 1070;
  }

  /* Motion Accessibility */
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
}
```

#### 1.2. Application CSS에 import 추가

**파일:** `app/assets/stylesheets/application.css`

```css
/*
 * This is a manifest file that'll be compiled into application.css.
 */

@import "./tokens.css";

/* 기존 imports... */
```

---

### Phase 2: 레이아웃 색상 개선 (Week 1-2)

#### 2.1. 네비게이션 개선

**파일:** `app/views/layouts/application.html.erb`

**Before:**
```erb
<nav class="bg-green-700 border-green-800">
```

**After:**
```erb
<nav class="bg-slate-800 border-b border-slate-700">
```

#### 2.2. 버튼 색상 통일

**Before:**
```erb
<button class="bg-green-600 hover:bg-green-500 focus:ring-green-300">
```

**After:**
```erb
<button class="bg-green-500 hover:bg-green-600 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900">
```

#### 2.3. 링크 호버 색상 통일

**Before:**
```erb
<!-- 혼재된 사용 -->
hover:text-green-400
hover:text-green-300
```

**After:**
```erb
<!-- 통일 -->
hover:text-green-400
```

---

### Phase 3: 접근성 개선 (Week 2)

#### 3.1. 포커스 스타일 추가

**모든 상호작용 요소에 추가:**
```erb
focus:outline-none
focus:ring-2
focus:ring-green-500
focus:ring-offset-2
focus:ring-offset-slate-900
```

**적용 대상:**
- [ ] 모든 버튼
- [ ] 모든 링크
- [ ] 모든 입력 필드
- [ ] 네비게이션 메뉴 토글

#### 3.2. Skip Link 추가

**파일:** `app/views/layouts/application.html.erb`

```erb
<body class="bg-slate-900 text-slate-200 min-h-screen flex flex-col">
  <!-- Skip Link (최상단) -->
  <a href="#main-content"
     class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-green-500 focus:text-white focus:rounded-lg">
    본문으로 건너뛰기
  </a>

  <!-- 기존 네비게이션... -->

  <main id="main-content" class="container mx-auto px-4 py-8 grow">
    <%= yield %>
  </main>
</body>
```

#### 3.3. ARIA 레이블 추가

**네비게이션:**
```erb
<nav class="..." aria-label="주 네비게이션">
```

**검색 폼:**
```erb
<%= form_with url: articles_path, method: :get, local: true,
    role: "search",
    aria-label: "기사 검색" do |form| %>
```

**모바일 메뉴 토글:**
```erb
<label for="mobile-menu-toggle"
       class="..."
       aria-label="메뉴 열기/닫기">
```

---

### Phase 4: daisyUI 통합 및 컴포넌트 추출 (Week 3-4)

#### 4.0. daisyUI 클래스 통일

daisyUI `btn` 클래스를 프로젝트 전반에 일관되게 적용합니다.

**목표:**
- Madmin 뷰의 `btn btn-danger bg-red-600 ...` 같은 중복 스타일 정리 → `btn btn-error`
- Tailwind 직접 사용 버튼을 daisyUI `btn` 클래스로 마이그레이션
- `ApplicationHelper`의 `btn_class`, `btn_link_to` 헬퍼를 Phlex 컴포넌트에서도 활용

**Before (Madmin):**
```erb
class="btn btn-danger bg-red-600 text-white rounded px-4 py-2 hover:bg-red-700"
class="btn btn-success bg-green-600 text-white rounded px-4 py-2 hover:bg-green-700"
```

**After:**
```erb
class="btn btn-error"
class="btn btn-success"
```

#### 4.1. Button Component (daisyUI 기반)

**파일:** `app/components/ui/button_component.rb`

daisyUI `btn` 클래스를 기반으로 하되, 프로젝트 디자인 시스템과 일관되게 확장합니다.

```ruby
# frozen_string_literal: true

class Ui::ButtonComponent < Components::Base
  def initialize(
    variant: :primary,
    size: :md,
    type: :button,
    outline: false,
    href: nil,
    **attrs
  )
    @variant = variant
    @size = size
    @type = type
    @outline = outline
    @href = href
    @attrs = attrs
  end

  def template
    if @href
      a(href: @href, **attrs_with_classes) { yield }
    else
      button(type: @type, **attrs_with_classes) { yield }
    end
  end

  private

  def attrs_with_classes
    @attrs.merge(class: button_classes)
  end

  def button_classes
    classes = ["btn"]
    classes << variant_class
    classes << "btn-outline" if @outline
    classes << size_class
    classes.join(" ")
  end

  def variant_class
    case @variant
    when :primary   then "btn-primary"
    when :secondary then "btn-secondary"
    when :ghost     then "btn-ghost"
    when :danger    then "btn-error"
    when :success   then "btn-success"
    end
  end

  def size_class
    case @size
    when :sm then "btn-sm"
    when :md then nil
    when :lg then "btn-lg"
    end
  end
end
```

**사용 예시:**
```erb
<!-- daisyUI 기반 컴포넌트 -->
<%= render Ui::ButtonComponent.new(variant: :primary) do %>
  저장하기
<% end %>

<!-- 헬퍼 메서드 (기존 호환) -->
<%= btn_link_to "모든 기사 보기", articles_path, variant: :secondary %>

<!-- 아웃라인 스타일 -->
<%= render Ui::ButtonComponent.new(variant: :primary, outline: true, size: :sm) do %>
  취소
<% end %>
```

#### 4.2. Card Component

**파일:** `app/components/ui/card_component.rb`

```ruby
# frozen_string_literal: true

class Ui::CardComponent < Components::Base
  def initialize(hover: true, **attrs)
    @hover = hover
    @attrs = attrs
  end

  def template
    article(**attrs_with_classes) do
      yield
    end
  end

  private

  def attrs_with_classes
    @attrs.merge(class: card_classes)
  end

  def card_classes
    classes = [
      "bg-slate-800 border border-slate-700",
      "rounded-xl p-6",
      "shadow-lg",
    ]

    if @hover
      classes << "transition-all duration-200"
      classes << "hover:border-slate-600 hover:shadow-xl hover:-translate-y-1"
    end

    classes.join(" ")
  end
end
```

#### 4.3. Badge Component

**파일:** `app/components/ui/badge_component.rb`

```ruby
# frozen_string_literal: true

class Ui::BadgeComponent < Components::Base
  def initialize(variant: :default, **attrs)
    @variant = variant
    @attrs = attrs
  end

  def template
    span(**attrs_with_classes) do
      yield
    end
  end

  private

  def attrs_with_classes
    @attrs.merge(class: badge_classes)
  end

  def badge_classes
    classes = [
      "inline-flex items-center",
      "px-3 py-1",
      "text-sm font-medium",
      "rounded-full",
    ]

    classes << variant_classes

    classes.join(" ")
  end

  def variant_classes
    case @variant
    when :primary
      "bg-green-500/10 text-green-400"
    when :secondary
      "bg-slate-500/10 text-slate-400"
    when :success
      "bg-green-500/10 text-green-400"
    when :warning
      "bg-amber-500/10 text-amber-400"
    when :error
      "bg-red-500/10 text-red-400"
    when :info
      "bg-blue-500/10 text-blue-400"
    else
      "bg-slate-500/10 text-slate-400"
    end
  end
end
```

---

### Phase 5: 기존 뷰 리팩토링 (Week 4)

#### 5.1. 색상 통일

**검색 및 교체:**
```bash
# gray-900 → slate-900
find app/views -type f -name "*.erb" -exec sed -i '' 's/gray-900/slate-900/g' {} +

# gray-800 → slate-800
find app/views -type f -name "*.erb" -exec sed -i '' 's/gray-800/slate-800/g' {} +

# gray-700 → slate-700
find app/views -type f -name "*.erb" -exec sed -i '' 's/gray-700/slate-700/g' {} +

# gray-200 → slate-200
find app/views -type f -name "*.erb" -exec sed -i '' 's/gray-200/slate-200/g' {} +

# gray-100 → slate-100
find app/views -type f -name "*.erb" -exec sed -i '' 's/gray-100/slate-100/g' {} +

# text-gray-100 → text-slate-50 (제목용)
find app/views -type f -name "*.erb" -exec sed -i '' 's/text-gray-100/text-slate-50/g' {} +
```

**⚠️ 주의:**
- 자동 교체 전 Git commit 필수
- green-50, green-100 등 알림 색상은 유지
- 수동 검토 필요한 경우 별도 처리

#### 5.2. 네비게이션 리팩토링

**컴포넌트 추출:**
```ruby
# app/components/navigation/nav_link_component.rb
class Navigation::NavLinkComponent < Components::Base
  def initialize(text:, href:, active: false)
    @text = text
    @href = href
    @active = active
  end

  def template
    a(
      href: @href,
      class: link_classes,
      aria: aria_attributes
    ) do
      plain @text
    end
  end

  private

  def link_classes
    base = "block py-2 px-3 rounded-lg transition-colors duration-200 min-h-11 flex items-center"
    base += " focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-800"

    if @active
      "#{base} bg-slate-700 text-white"
    else
      "#{base} text-slate-200 hover:bg-slate-700 hover:text-white"
    end
  end

  def aria_attributes
    { current: @active ? "page" : nil }.compact
  end
end
```

**사용:**
```erb
<%= render Navigation::NavLinkComponent.new(
  text: "홈",
  href: root_path,
  active: current_page?(root_path)
) %>
```

---

## 테스트 계획

### 수동 테스트 체크리스트

#### 시각적 회귀 테스트
- [ ] 홈페이지 레이아웃 확인
- [ ] 기사 상세 페이지 확인
- [ ] 댓글 섹션 확인
- [ ] 네비게이션 메뉴 확인 (데스크톱/모바일)
- [ ] 폼 입력 확인 (로그인, 기사 등록)

#### 접근성 테스트
- [ ] 키보드로만 전체 네비게이션 가능 (Tab, Enter, Space)
- [ ] 포커스 상태 모든 요소에서 시각적으로 명확
- [ ] 스크린 리더 테스트 (VoiceOver/NVDA)
- [ ] 색상 대비 도구로 검증 (WebAIM Contrast Checker)
- [ ] Skip Link 작동 확인

#### 반응형 테스트
- [ ] 375px (모바일 최소)
- [ ] 768px (태블릿)
- [ ] 1024px (데스크톱)
- [ ] 1440px (대형 데스크톱)

#### 브라우저 테스트
- [ ] Chrome (최신)
- [ ] Firefox (최신)
- [ ] Safari (최신)
- [ ] Edge (최신)

### 자동화 테스트

#### Lighthouse 점수 목표
- **Performance:** 90+
- **Accessibility:** 95+
- **Best Practices:** 90+
- **SEO:** 95+

#### axe-core 테스트
```bash
# axe-core CLI 설치
npm install -g @axe-core/cli

# 접근성 테스트 실행
axe https://ruby-news.kr --exit
```

---

## 마이그레이션 전략

### 점진적 롤아웃

#### Week 1
1. CSS 변수 파일 생성 (`tokens.css`)
2. 레이아웃 파일만 색상 변경
3. Production 배포 및 모니터링

#### Week 2
1. 접근성 개선사항 적용
2. 포커스 스타일, Skip Link, ARIA 레이블
3. Production 배포 및 사용자 피드백 수집

#### Week 3-4
1. 컴포넌트 추출 (Button, Card, Badge)
2. 기존 뷰 파일 점진적 마이그레이션
3. 각 페이지별 배포 및 QA

### 롤백 계획

각 배포 전 Git 태그 생성:
```bash
git tag -a design-system-v1.0.0 -m "Before design system refactor"
git push origin design-system-v1.0.0
```

문제 발생 시 롤백:
```bash
git revert <commit-hash>
```

---

## 성공 지표

### 정량적 지표
- [ ] Lighthouse Accessibility 점수: 95+ 달성
- [ ] 색상 대비: 모든 텍스트 4.5:1 이상
- [ ] 키보드 네비게이션: 100% 요소 접근 가능
- [ ] 모바일 반응성: 100% 페이지 가로 스크롤 없음

### 정성적 지표
- [ ] 코드 리뷰에서 디자인 일관성 문제 제기 감소
- [ ] 신규 컴포넌트 개발 시간 단축
- [ ] 사용자 피드백에서 UI/UX 개선 언급 증가

---

## 참고 자료

### 내부 문서
- [디자인 시스템 가이드](./DESIGN_SYSTEM.md)
- [마스터 디자인 시스템](../design-system/ruby-news/MASTER.md)
- [코드 컨벤션](../AGENTS.md)

### 외부 리소스
- [Tailwind CSS - Customizing Colors](https://tailwindcss.com/docs/customizing-colors)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [ViewComponent Best Practices](https://viewcomponent.org/guide/)

---

## 다음 단계

1. **즉시 시작 가능:**
   - [ ] `app/assets/stylesheets/tokens.css` 생성
   - [ ] `application.css`에 import 추가

2. **팀 리뷰 필요:**
   - [ ] 색상 팔레트 최종 확인
   - [ ] 컴포넌트 API 설계 리뷰

3. **의사결정 필요:**
   - [ ] 라이트 모드 지원 여부
   - [ ] 컴포넌트 마이그레이션 우선순위
   - [ ] 배포 일정 조율

---

## 질문/논의 사항

프로젝트 팀과 논의가 필요한 항목:

1. **색상 팔레트 변경에 대한 동의**
   - green-700 → slate-800 (네비게이션)
   - 기존 사용자가 익숙한 green 브랜딩 유지 vs 개선된 대비

2. **컴포넌트 우선순위**
   - Button, Card, Badge 외 추가 필요 컴포넌트
   - 기존 ViewComponent와 신규 Phlex 컴포넌트 혼용 전략
   - daisyUI 시맨틱 클래스 활용 범위 (btn, alert, modal 등)

3. **배포 일정**
   - 점진적 배포 vs 한 번에 배포
   - QA 리소스 할당

---

**작성자:** Claude Code
**검토 필요:** 프로젝트 팀
