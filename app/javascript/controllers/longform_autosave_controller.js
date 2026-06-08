import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  schedule() {
    if (this.timeout) clearTimeout(this.timeout)
    this.setStatus("저장 대기 중")
    this.timeout = setTimeout(() => this.save(), 800)
  }

  async save() {
    this.setStatus("저장 중")

    try {
      const headers = { "Accept": "application/json" }
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      if (csrfToken) headers["X-CSRF-Token"] = csrfToken

      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers,
        body: new FormData(this.element)
      })

      if (!response.ok) {
        this.setStatus("저장 실패")
        return
      }

      const payload = await response.json()
      this.setStatus(payload.saved_at ? `저장됨 ${payload.saved_at}` : "저장됨")
    } catch {
      this.setStatus("저장 실패")
    }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
