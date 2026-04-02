import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-count"
export default class extends Controller {
  static targets = ["input", "counter"]
  static values = {
    maxLength: Number,
    warningThreshold: { type: Number, default: 0.8 },
    dangerThreshold: { type: Number, default: 0.9 }
  }

  connect() {
    this.updateCount()
  }

  updateCount() {
    const currentLength = this.currentLength
    this.counterTarget.textContent = currentLength

    if (this.hasMaxLengthValue) {
      const percentage = currentLength / this.maxLengthValue

      const classList = this.counterTarget.classList
      classList.remove("text-content-muted", "text-warning", "text-danger-text")

      if (percentage >= this.dangerThresholdValue) {
        classList.add("text-danger-text")
      } else if (percentage >= this.warningThresholdValue) {
        classList.add("text-warning")
      } else {
        classList.add("text-content-muted")
      }
    }
  }

  get currentLength() {
    if (!this.hasInputTarget) return 0

    if (this.inputTarget.tagName === "LEXXY-EDITOR") {
      return this.inputTarget.toString().length
    }

    return this.inputTarget.value?.length ?? 0
  }
}
