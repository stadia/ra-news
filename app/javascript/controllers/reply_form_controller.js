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

    // Reset the form before hiding it
    const form = this.formTarget.querySelector("form")
    if (form) {
      form.reset()
      // Reset character counter if present
      const counter = form.querySelector("[data-character-count-target='counter']")
      if (counter) counter.textContent = "0"
    }

    this.formTarget.classList.add("hidden")
  }
}
