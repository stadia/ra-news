import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="comment-form"
export default class extends Controller {
  reset(event) {
    // Only reset on successful submission
    if (!event?.detail?.success) return

    const form = this.element.querySelector("form")
    if (form) {
      form.reset()

      // Reset character counter if present
      const counter = form.querySelector("[data-character-count-target='counter']")
      if (counter) counter.textContent = "0"
    }
  }
}
