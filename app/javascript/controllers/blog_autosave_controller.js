import { Controller } from "@hotwired/stimulus"

// Periodic autosave for the blog editor. Saves on a fixed interval only
// when there are unsaved changes — entering the editor or sitting idle never
// triggers a save. The draft is created lazily: the first save POSTs to
// #create, then the controller rewires itself to PATCH #update in place.
export default class extends Controller {
  static targets = ["status", "publishButton", "methodField"]
  static values = {
    persisted: Boolean,
    initialDirty: Boolean,
    saveUrl: String,
    interval: { type: Number, default: 30000 },
    pendingText: String,
    savingText: String,
    savedText: String,
    failedText: String
  }

  connect() {
    this.dirty = this.initialDirtyValue
    this.inflight = null
    if (this.dirty) this.setStatus(this.pendingTextValue)
    this.timer = setInterval(() => this.tick(), this.intervalValue)
  }

  disconnect() {
    this.stop()
  }

  // input / lexxy:change on the title and body fields.
  markDirty() {
    this.dirty = true
    this.setStatus(this.pendingTextValue)
  }

  // Bound to form submit (preview/publish): stop the timer and abort any
  // in-flight autosave so a stale request can't land after the submit and
  // overwrite the just-sent content.
  stop() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
    this.abortInflight()
  }

  tick() {
    if (this.dirty) this.save()
  }

  async save() {
    this.abortInflight()
    const controller = new AbortController()
    this.inflight = controller
    // Capture point: edits arriving during the request re-mark dirty so the
    // next tick saves them.
    this.dirty = false
    this.setStatus(this.savingTextValue)

    try {
      const headers = { "Accept": "application/json" }
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      if (csrfToken) headers["X-CSRF-Token"] = csrfToken

      const response = await fetch(this.saveUrlValue, {
        method: this.persistedValue ? "PATCH" : "POST",
        headers,
        body: new FormData(this.element),
        signal: controller.signal
      })

      if (!response.ok) {
        this.dirty = true
        this.setStatus(this.failedTextValue)
        return
      }

      const payload = await response.json()
      if (!this.persistedValue) this.markPersisted(payload)
      this.setStatus(payload.saved_at ? `${this.savedTextValue} ${payload.saved_at}` : this.savedTextValue)
    } catch (error) {
      if (error.name === "AbortError") return
      this.dirty = true
      this.setStatus(this.failedTextValue)
    } finally {
      if (this.inflight === controller) this.inflight = null
    }
  }

  abortInflight() {
    if (this.inflight) {
      this.inflight.abort()
      this.inflight = null
    }
  }

  // The first autosave created the draft; rewire the form from "create" to
  // "update" so later saves PATCH and the buttons target the persisted post.
  markPersisted(payload) {
    if (!payload.save_url) return

    this.persistedValue = true
    this.saveUrlValue = payload.save_url
    this.element.action = payload.form_url
    if (this.hasMethodFieldTarget) this.methodFieldTarget.value = "patch"
    if (this.hasPublishButtonTarget) {
      this.publishButtonTarget.formAction = payload.publish_url
      this.publishButtonTarget.name = "_method"
      this.publishButtonTarget.value = "patch"
    }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
