import { Controller } from "@hotwired/stimulus"
import { resetFormWithCounter } from "utils/form_helpers"

// Connects to data-controller="post-form"
export default class extends Controller {
  connect() {
    this.beforeCache = this.beforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
  }

  reset(event) {
    if (!event?.detail?.success) return

    resetFormWithCounter(this.element)
  }

  beforeCache() {
    resetFormWithCounter(this.element)
  }
}
