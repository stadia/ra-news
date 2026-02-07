import { Controller } from "@hotwired/stimulus"
import { resetFormWithCounter } from "utils/form_helpers"

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
    resetFormWithCounter(this.formTarget)

    this.formTarget.classList.add("hidden")
  }
}
