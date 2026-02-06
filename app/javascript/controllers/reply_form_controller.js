import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reply-form"
export default class extends Controller {
  static targets = ["form"]

  toggle() {
    if (!this.hasFormTarget) return
    this.formTarget.classList.toggle("hidden")
  }

  close(event) {
    if (!this.hasFormTarget) return
    if (!event?.detail?.success) return
    this.formTarget.classList.add("hidden")
  }
}
