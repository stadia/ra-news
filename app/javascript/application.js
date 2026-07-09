// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "@rails/activestorage";
import "controllers";

// lexxy(리치텍스트 에디터, ~250KB)는 에디터가 있는 페이지에서만 동적 로드한다.
// 서버가 <lexxy-editor> 커스텀 엘리먼트를 렌더하므로 존재 여부로 판단하며,
// dynamic import는 모듈 캐시를 타서 Turbo 네비게이션마다 재요청하지 않는다.
// (turbo:load는 첫 로드와 Turbo 네비게이션 모두에서 발생하므로 두 경로를 모두 커버)
document.addEventListener("turbo:load", () => {
  if (!document.querySelector("lexxy-editor")) return;

  // 로드 실패를 삼키지 않는다: 조용히 죽으면 에디터가 동작하지 않으므로
  // 콘솔/Sentry에 신호를 남긴다.
  import("lexxy").catch((error) => {
    console.error("Failed to load lexxy editor:", error);
    window.Sentry?.captureException?.(error);
  });
});
