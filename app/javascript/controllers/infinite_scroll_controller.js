// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

// Turbo Frame을 viewport 근처에서 미리 로드해 feed append 지연을 줄인다.
export default class extends Controller {
  static values = {
    preloadMargin: { type: String, default: "640px" },
    src: String,
  }

  connect() {
    this.beforeFetchRequest = () => {
      this.element.setAttribute("aria-busy", "true")
    }

    this.frameLoad = () => {
      this.element.removeAttribute("aria-busy")
      this.disconnectObserver()
    }

    this.element.addEventListener("turbo:before-fetch-request", this.beforeFetchRequest)
    this.element.addEventListener("turbo:frame-load", this.frameLoad)
    this.observeForPreload()
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-fetch-request", this.beforeFetchRequest)
    this.element.removeEventListener("turbo:frame-load", this.frameLoad)
    this.disconnectObserver()
  }

  observeForPreload() {
    if (!this.hasSrcValue || this.element.hasAttribute("src")) return

    if (!("IntersectionObserver" in window)) {
      this.loadFrame()
      return
    }

    this.observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) this.loadFrame()
      },
      { rootMargin: `0px 0px ${this.preloadMarginValue} 0px` }
    )

    this.observer.observe(this.element)
  }

  loadFrame() {
    this.disconnectObserver()
    this.element.setAttribute("src", this.srcValue)
  }

  disconnectObserver() {
    if (!this.observer) return

    this.observer.disconnect()
    this.observer = null
  }
}
