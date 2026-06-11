import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["image", "fallback"];

  connect() {
    if (!this.hasImageTarget) {
      return;
    }

    // Only act on an image that has already *failed* to load. A still-loading
    // image must stay visible — hiding it (display:none) would also stop a
    // `loading="lazy"` image from loading at all, so it would never appear.
    // Late load/error events are handled by the load/error actions.
    if (this.imageTarget.complete && this.imageTarget.naturalWidth === 0) {
      this.showFallback();
    }
  }

  showImage() {
    this.imageTargets.forEach((image) => image.classList.remove("hidden"));
    this.fallbackTargets.forEach((fallback) =>
      fallback.classList.add("hidden"),
    );
  }

  showFallback() {
    this.imageTargets.forEach((image) => image.classList.add("hidden"));
    this.fallbackTargets.forEach((fallback) =>
      fallback.classList.remove("hidden"),
    );
  }
}
