import { Controller } from "@hotwired/stimulus"

const FEEDBACK_DURATION = 2000

export default class extends Controller {
  static values = { url: String }
  static targets = ["label"]

  async copy() {
    try {
      const res = await fetch(this.urlValue, {
        headers: { Accept: "text/markdown" }
      })
      const text = await res.text()
      await navigator.clipboard.writeText(text)
      this.showFeedback()
    } catch (e) {
      console.warn("Failed to copy markdown:", e)
    }
  }

  showFeedback() {
    if (!this.hasLabelTarget) return

    const original = this.labelTarget.textContent
    const done = this.labelTarget.dataset.doneLabel
    if (!done) return

    this.labelTarget.textContent = done
    clearTimeout(this.feedbackTimeout)
    this.feedbackTimeout = setTimeout(() => {
      this.labelTarget.textContent = original
    }, FEEDBACK_DURATION)
  }
}
