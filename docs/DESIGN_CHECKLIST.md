# 디자인 시스템 체크리스트

> **빠른 참조:** 새로운 UI 컴포넌트나 페이지를 만들 때 사용하는 체크리스트

---

## 색상 사용 가이드

### ✅ 사용해야 할 색상

```css
/* Background */
bg-slate-900     /* Body 배경 */
bg-slate-800     /* 카드 배경 */
bg-slate-700     /* 입력 필드, 버튼 (Secondary) */

/* Text */
text-slate-50    /* 제목 */
text-slate-200   /* 본문 */
text-slate-400   /* 보조 텍스트 */

/* Accent/CTA */
bg-green-500     /* Primary 버튼 */
bg-green-600     /* Primary 버튼 hover */
text-green-400   /* 링크, 아이콘 */

/* Border */
border-slate-700 /* 기본 테두리 */
border-slate-600 /* Hover 테두리 */
```

### ❌ 사용하지 말아야 할 색상

```css
bg-gray-*        /* gray 대신 slate 사용 */
bg-green-700     /* 네비게이션에 사용 금지 */
bg-green-800     /* 너무 어두움 */
text-green-300   /* 일관성 없음, green-400 사용 */
```

---

## 컴포넌트 체크리스트

### 버튼

```erb
<!-- ✅ Good -->
<button class="
  px-4 py-2
  bg-green-500 hover:bg-green-600
  text-white font-medium
  rounded-lg
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
  cursor-pointer
">
  클릭
</button>

<!-- ❌ Bad -->
<button class="bg-green-700 hover:bg-green-600">
  클릭
</button>
```

**필수 클래스:**
- [ ] `cursor-pointer`
- [ ] `focus:outline-none focus:ring-2 focus:ring-* focus:ring-offset-2 focus:ring-offset-slate-900`
- [ ] `transition-colors duration-200` (또는 `transition-all`)
- [ ] 호버 상태 (`hover:bg-*`)

### 카드

```erb
<!-- ✅ Good -->
<article class="
  bg-slate-800 border border-slate-700
  rounded-xl p-6
  shadow-lg
  transition-all duration-200
  hover:border-slate-600 hover:shadow-xl
">
  내용
</article>

<!-- ❌ Bad -->
<div class="bg-gray-800">
  내용
</div>
```

**필수 클래스:**
- [ ] `bg-slate-800 border border-slate-700`
- [ ] `rounded-xl` (또는 `rounded-lg`)
- [ ] `shadow-lg` (또는 `shadow-md`)
- [ ] 호버 시 변화 (border, shadow, transform)

### 링크

```erb
<!-- ✅ Good -->
<a href="#" class="
  text-slate-200 hover:text-white
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900
">
  링크
</a>

<!-- ❌ Bad -->
<a href="#" class="text-gray-200">
  링크
</a>
```

**필수 클래스:**
- [ ] `text-slate-*`
- [ ] `hover:text-*`
- [ ] `focus:*` (포커스 스타일)
- [ ] `transition-colors duration-200`

### 입력 필드

```erb
<!-- ✅ Good -->
<input type="text" class="
  w-full px-4 py-2
  bg-slate-800 border border-slate-700
  rounded-lg
  text-slate-100 placeholder-slate-500
  transition-colors duration-200
  focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent
">

<!-- ❌ Bad -->
<input type="text" class="bg-white text-gray-900">
```

**필수 클래스:**
- [ ] `bg-slate-800 border border-slate-700`
- [ ] `text-slate-100 placeholder-slate-500`
- [ ] `focus:outline-none focus:ring-2 focus:ring-green-500`
- [ ] `rounded-lg`

---

## 접근성 체크리스트

### 키보드 네비게이션

**모든 상호작용 요소:**
- [ ] Tab으로 포커스 가능
- [ ] Enter/Space로 활성화 가능
- [ ] 포커스 스타일 시각적으로 명확
- [ ] 논리적 Tab 순서

**필수 클래스:**
```css
focus:outline-none
focus:ring-2
focus:ring-green-500
focus:ring-offset-2
focus:ring-offset-slate-900
```

### ARIA 레이블

**필수 ARIA 속성:**
- [ ] 아이콘 버튼: `aria-label="설명"`
- [ ] 네비게이션: `aria-label="주 네비게이션"`
- [ ] 검색 폼: `role="search"`, `aria-label="검색"`
- [ ] 현재 페이지: `aria-current="page"`
- [ ] 랜드마크: `<nav>`, `<main>`, `<footer>` 사용

**예시:**
```erb
<button aria-label="메뉴 열기">
  <%= heroicon "bars-3" %>
</button>

<nav aria-label="주 네비게이션">
  <a href="/" aria-current="page">홈</a>
</nav>
```

### 색상 대비

**최소 대비율:**
- 일반 텍스트: **4.5:1**
- 큰 텍스트 (18pt+ 또는 14pt bold): **3:1**

**검증된 조합:**
```css
✅ text-slate-50 on bg-slate-900   (18.9:1)
✅ text-slate-200 on bg-slate-900  (14.1:1)
✅ text-green-400 on bg-slate-900  (8.2:1)
✅ text-slate-400 on bg-slate-900  (5.9:1)
```

### 모션 접근성

**prefers-reduced-motion 지원:**
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

**CSS에 포함:** `app/assets/stylesheets/tokens.css`

---

## 반응형 디자인 체크리스트

### 브레이크포인트

```css
/* Mobile First */
/* 기본: 375px 이상 */
sm:  640px   /* Tailwind sm */
md:  768px   /* 태블릿 */
lg:  1024px  /* 데스크톱 */
xl:  1280px  /* 대형 데스크톱 */
2xl: 1536px  /* 초대형 */
```

### 테스트 해상도

**필수 테스트:**
- [ ] 375px (iPhone SE)
- [ ] 768px (iPad 세로)
- [ ] 1024px (iPad 가로, 작은 노트북)
- [ ] 1440px (일반 데스크톱)

### 반응형 패턴

**네비게이션:**
```erb
<nav class="
  hidden md:flex        <!-- 모바일 숨김, 태블릿+ 표시 -->
  md:space-x-8          <!-- 태블릿+ 수평 간격 -->
">
```

**그리드:**
```erb
<div class="
  grid
  grid-cols-1           <!-- 모바일: 1열 -->
  md:grid-cols-2        <!-- 태블릿: 2열 -->
  lg:grid-cols-3        <!-- 데스크톱: 3열 -->
  gap-6
">
```

**텍스트 크기:**
```erb
<h1 class="
  text-2xl              <!-- 모바일: 24px -->
  md:text-3xl           <!-- 태블릿: 30px -->
  lg:text-4xl           <!-- 데스크톱: 36px -->
">
```

---

## 성능 체크리스트

### 이미지

**최적화:**
- [ ] WebP 포맷 사용
- [ ] `loading="lazy"` 추가 (뷰포트 밖)
- [ ] `srcset` 사용 (반응형)
- [ ] 적절한 크기 (원본 크기 > 표시 크기 x2)
- [ ] alt 텍스트 작성

**예시:**
```erb
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="설명" loading="lazy">
</picture>
```

### 폰트

**현재 설정:**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap">
```

**체크:**
- [ ] `preconnect` 있음
- [ ] `display=swap` 있음
- [ ] 필요한 weight만 로드 (400, 500, 700)

### 애니메이션

**가이드라인:**
- [ ] 150-300ms 사이 (빠른-보통)
- [ ] `ease-out` (등장), `ease-in` (퇴장)
- [ ] `transform`/`opacity` 사용 (width/height 대신)
- [ ] 무한 애니메이션 지양 (로딩 제외)

**예시:**
```css
/* ✅ Good */
transition: transform 200ms ease-out, opacity 200ms ease-out;

/* ❌ Bad */
transition: width 500ms linear;
```

---

## 코드 리뷰 체크리스트

### Pull Request 전

**시각적 검토:**
- [ ] 모든 페이지/컴포넌트 브라우저에서 확인
- [ ] 375px, 768px, 1024px, 1440px 테스트
- [ ] Chrome, Firefox, Safari 확인

**접근성 검토:**
- [ ] 키보드로만 전체 네비게이션 테스트
- [ ] 포커스 스타일 모든 요소 확인
- [ ] Lighthouse Accessibility 점수 95+ 확인
- [ ] axe DevTools 경고 없음

**코드 품질:**
- [ ] 하드코딩된 색상 없음 (Tailwind 클래스 사용)
- [ ] 중복 스타일 없음 (컴포넌트 재사용)
- [ ] ARIA 레이블 적절히 사용
- [ ] prefers-reduced-motion 지원

**문서화:**
- [ ] 새로운 컴포넌트는 README 또는 Storybook 추가
- [ ] 색상 변경 시 DESIGN_SYSTEM.md 업데이트

---

## 빠른 명령어

### Lighthouse 테스트
```bash
# Chrome DevTools > Lighthouse 탭
# 또는 CLI:
npm install -g lighthouse
lighthouse https://ruby-news.kr --view
```

### 접근성 테스트
```bash
# axe-core CLI
npm install -g @axe-core/cli
axe https://ruby-news.kr --exit
```

### 색상 대비 확인
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Contrast Ratio](https://contrast-ratio.com/)

### 반응형 테스트 (Chrome)
```
DevTools (F12) > Toggle Device Toolbar (Ctrl+Shift+M)
```

---

## 자주 묻는 질문

### Q: green-700을 어디에 사용해야 하나요?
**A:** 네비게이션 배경에는 `bg-slate-800`을 사용하세요. `green-700`은 더 이상 권장하지 않습니다.

### Q: 새로운 컴포넌트를 만들어야 할까요?
**A:** 같은 스타일이 3곳 이상에서 사용되면 컴포넌트로 추출하세요.

### Q: 포커스 스타일이 너무 많은 클래스를 요구합니다.
**A:** 버튼 컴포넌트를 사용하면 자동으로 포함됩니다:
```erb
<%= render Ui::ButtonComponent.new(variant: :primary) do %>
  클릭
<% end %>
```

### Q: Tailwind 클래스가 너무 길어집니다.
**A:** 컴포넌트로 추출하거나, `@apply`를 사용하세요 (단, 가독성이 좋을 때만):
```css
.btn-primary {
  @apply px-4 py-2 bg-green-500 hover:bg-green-600 text-white font-medium rounded-lg;
}
```

### Q: 다크 모드만 지원하나요?
**A:** 현재는 다크 모드만 지원합니다. 라이트 모드는 향후 계획입니다.

---

## 참고 문서

- [전체 디자인 시스템 가이드](./DESIGN_SYSTEM.md)
- [개선 액션 플랜](./DESIGN_IMPROVEMENTS.md)
- [마스터 디자인 시스템](../design-system/ruby-news/MASTER.md)
- [코드 컨벤션](../AGENTS.md)

---

**마지막 업데이트:** 2026-02-08
