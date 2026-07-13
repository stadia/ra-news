// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "@rails/activestorage";
import "controllers";

// lexxy(리치텍스트 에디터, ~917KB)는 에디터가 있는 페이지에서만 동적 로드한다.
// 서버가 <lexxy-editor> 커스텀 엘리먼트를 렌더하므로 존재 여부로 판단하며,
// dynamic import는 모듈 캐시를 타서 Turbo 네비게이션마다 재요청하지 않는다.
// (turbo:load는 첫 로드와 Turbo 네비게이션 모두에서 발생하므로 두 경로를 모두 커버)
//
// 에디터가 있는 페이지에서는 에디터 폼 컴포넌트(Components::Base#lexxy_editor_asset_tags)가
// <link rel="modulepreload" href=lexxy.js>를 함께 렌더하므로, HTML 파싱 즉시 다운로드가
// 시작되어 아래 import("lexxy")는 캐시에서 즉시 해석된다 → 에디터가 뒤늦게 나타나는
// 지연이 사라진다. import 로직 자체는 그대로 두어(에디터 없는 페이지는 힌트가 안 나가
// lazy 유지) Sentry 에러 핸들링과 Turbo 네비게이션 모듈 캐시 동작을 보존한다.
document.addEventListener("turbo:load", () => {
  if (!document.querySelector("lexxy-editor")) return;

  // 로드 실패를 삼키지 않는다: 조용히 죽으면 에디터가 동작하지 않으므로
  // 콘솔/Sentry에 신호를 남긴다.
  import("lexxy").catch((error) => {
    console.error("Failed to load lexxy editor:", error);
    window.Sentry?.captureException?.(error);
  });
});
