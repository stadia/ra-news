import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = {
    url: String,
    pendingText: String,
    savingText: String,
    savedText: String,
    failedText: String
  }

  connect() {
    this.timeout = null
    this.inflight = null
  }

  disconnect() {
    this.cancelPending()
  }

  // Bound to the form's submit event so a publish/preview navigation aborts any
  // pending or in-flight autosave. Otherwise an older PATCH could land after
  // the publish request and overwrite the just-submitted body.
  cancelPending() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    if (this.inflight) {
      this.inflight.abort()
      this.inflight = null
    }
  }

  schedule() {
    if (this.timeout) clearTimeout(this.timeout)
    this.setStatus(this.pendingTextValue)
    this.timeout = setTimeout(() => this.save(), 800)
  }

  async save() {
    if (this.inflight) this.inflight.abort()
    const controller = new AbortController()
    this.inflight = controller
    this.setStatus(this.savingTextValue)

    try {
      const headers = { "Accept": "application/json" }
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      if (csrfToken) headers["X-CSRF-Token"] = csrfToken

      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers,
        body: new FormData(this.element),
        signal: controller.signal
      })

      if (!response.ok) {
        this.setStatus(this.failedTextValue)
        return
      }

      const payload = await response.json()
      this.setStatus(payload.saved_at ? `${this.savedTextValue} ${payload.saved_at}` : this.savedTextValue)
    } catch (error) {
      if (error.name === "AbortError") return
      this.setStatus(this.failedTextValue)
    } finally {
      if (this.inflight === controller) this.inflight = null
    }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
