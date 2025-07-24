import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-count"
export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { maxLength: Number }

  connect() {
    // Initialize the character count on connect
    this.updateCount()
  }

  updateCount() {
    const currentLength = this.inputTarget.value.length
    this.counterTarget.textContent = currentLength

    // Optional: Add visual feedback when approaching limit
    if (this.hasMaxLengthValue) {
      const percentage = currentLength / this.maxLengthValue

      const classList = this.counterTarget.classList;
      classList.remove("text-red-400", "text-yellow-400", "text-gray-400");
      if (percentage >= 0.9) {
        classList.add("text-red-400");
      } else if (percentage >= 0.8) {
        classList.add("text-yellow-400");
      } else {
        classList.add("text-gray-400");
      }
    }
  }
}
