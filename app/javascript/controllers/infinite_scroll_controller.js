// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

// Turbo Frame의 lazy loading을 트리거하는 Intersection Observer
// turbo_frame_tag에 loading: :lazy와 함께 사용
export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:before-fetch-request", () => {
      this.element.setAttribute("aria-busy", "true")
    })

    this.element.addEventListener("turbo:frame-load", () => {
      this.element.removeAttribute("aria-busy")
    })
  }
}
