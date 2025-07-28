# CSS 기반 Scroll Reveal 애니메이션

## 개요

기존의 JavaScript 기반 복잡한 애니메이션 로직을 CSS 전환으로 대체하여 성능을 향상시키고 코드를 단순화했습니다.

## 주요 변경사항

### Before (JavaScript 기반)
- JavaScript에서 복잡한 setTimeout과 classList 조작
- CSS transition과 JavaScript 애니메이션이 혼재
- 더 많은 메모리 사용과 CPU 사용량

### After (CSS 기반)
- CSS transition만으로 모든 애니메이션 처리
- JavaScript는 IntersectionObserver만 사용하여 최소한의 로직
- 더 부드럽고 효율적인 애니메이션

## 사용법

### HTML 템플릿에서

```erb
<div data-controller="scroll-reveal"
     data-scroll-reveal-threshold-value="0.1">
  <div data-scroll-reveal-target="item" class="card">
    <!-- 콘텐츠 -->
  </div>
  <div data-scroll-reveal-target="item" class="card">
    <!-- 콘텐츠 -->
  </div>
</div>
```

### CSS 클래스 옵션

기본 애니메이션:
- `.scroll-reveal` - 기본 fade-in-up 애니메이션

다양한 애니메이션 타입:
- `.scroll-reveal-fade` - 페이드인만
- `.scroll-reveal-slide-left` - 왼쪽에서 슬라이드
- `.scroll-reveal-slide-right` - 오른쪽에서 슬라이드
- `.scroll-reveal-scale` - 스케일 애니메이션

### 스태거링 딜레이

CSS nth-child 선택자로 자동 스태거링:
- 첫 번째 아이템: 0.1초 딜레이
- 두 번째 아이템: 0.2초 딜레이
- 10번째 아이템까지 자동 지원

### 모던 브라우저 지원

최신 브라우저에서는 CSS View Transitions API 활용:
```css
.scroll-reveal-modern {
  animation: fadeInUp linear;
  animation-timeline: view();
  animation-range: entry 0% entry 30%;
}
```

## 성능 향상

1. **JavaScript 실행량 감소**: 애니메이션 로직을 CSS로 이관
2. **GPU 가속**: CSS transform과 opacity는 GPU에서 처리
3. **메모리 효율성**: setTimeout 제거로 메모리 누수 방지
4. **부드러운 애니메이션**: CSS transition의 네이티브 최적화 활용

## 마이그레이션

기존 코드는 변경 없이 그대로 작동합니다. 단지 애니메이션 처리 방식만 JavaScript에서 CSS로 변경되었습니다.
