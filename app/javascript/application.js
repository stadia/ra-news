// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "@rails/activestorage";
import "controllers";

// lexxy(리치텍스트 에디터, ~917KB)는 에디터가 있는 페이지에서만 동적 로드한다.
// 서버가 <lexxy-editor> 존재 여부로 판단하며, dynamic import는 모듈 캐시를 타서
// Turbo 네비게이션마다 재요청하지 않는다. 에디터 폼 컴포넌트가 함께 렌더하는
// <link rel="modulepreload">(Components::Base#lexxy_editor_asset_tags) 덕에
// 아래 import는 대개 캐시에서 즉시 해석된다.
document.addEventListener("turbo:load", () => {
  if (!document.querySelector("lexxy-editor")) return;

  // 로드 실패를 삼키지 않는다: 조용히 죽으면 에디터가 동작하지 않으므로
  // 콘솔/Sentry에 신호를 남긴다.
  import("lexxy").catch((error) => {
    console.error("Failed to load lexxy editor:", error);
    window.Sentry?.captureException?.(error);
  });
});
