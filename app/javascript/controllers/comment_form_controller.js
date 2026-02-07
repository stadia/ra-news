import { Controller } from "@hotwired/stimulus"
import { resetFormWithCounter } from "../utils/form_helpers"

// Connects to data-controller="comment-form"
export default class extends Controller {
  reset(event) {
    // Only reset on successful submission
    if (!event?.detail?.success) return

    resetFormWithCounter(this.element)
  }
}
