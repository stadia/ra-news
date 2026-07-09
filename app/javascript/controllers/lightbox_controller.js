import Lightbox from "@stimulus-components/lightbox";

export default class extends Lightbox {
  connect() {
    this.#ensureStylesheet();
    super.connect();
  }

  // lightgallery.css(~16KB)는 레이아웃에서 전역 로드하지 않고
  // 갤러리가 있는 페이지에서만, 한 번만 주입한다.
  #ensureStylesheet() {
    const href = this.element.dataset.lightboxStylesheet;
    if (!href || document.querySelector("link[data-lightgallery-css]")) return;

    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    link.dataset.lightgalleryCss = "";
    document.head.appendChild(link);
  }

  get defaultOptions() {
    return {
      selector: "a",
      download: false,
      counter: true,
      loop: true,
      animateThumb: false,
      allowMediaOverlap: true,
      toggleThumb: true,
    };
  }
}
