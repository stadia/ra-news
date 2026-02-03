import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    this.modalId = this.element.dataset.modalTarget
    this.modal = document.getElementById(this.modalId)
  }

  open() {
    if (this.modal) {
      this.modal.classList.remove("hidden")
      // Prevent body scrolling when modal is open
      document.body.style.overflow = "hidden"
    }
  }

  close() {
    if (this.modal) {
      this.modal.classList.add("hidden")
      // Restore body scrolling
      document.body.style.overflow = ""
    }
  }
}
